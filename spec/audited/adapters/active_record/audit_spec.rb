require File.expand_path('../active_record_spec_helper', __FILE__)

describe Audited::Adapters::ActiveRecord::Audit, :adapter => :active_record do
  let(:user) { Models::ActiveRecord::User.new :name => 'Testing' }

  describe "user=" do

    it "should be able to set the user to a model object" do
      subject.user = user
      subject.user.should == user
    end

    it "should be able to set the user to nil" do
      subject.user_id = 1
      subject.user_type = 'Models::ActiveRecord::User'
      subject.username = 'joe'

      subject.user = nil

      subject.user.should be_nil
      subject.user_id.should be_nil
      subject.user_type.should be_nil
      subject.username.should be_nil
    end

    it "should be able to set the user to a string" do
      subject.user = 'test'
      subject.user.should == 'test'
    end

    it "should clear model when setting to a string" do
      subject.user = user
      subject.user = 'testing'
      subject.user_id.should be_nil
      subject.user_type.should be_nil
    end

    it "should clear the username when setting to a model" do
      subject.username = 'test'
      subject.user = user
      subject.username.should be_nil
    end

  end

  describe "transaction ids" do
    it "should not assign a transaction id if there is none" do
      user = Models::ActiveRecord::User.create! :name => 'Transaction Tester'
      user.audits.first.transaction_id.should be_nil
      user.update_attribute :name, "New Name"
      user.audits.last.transaction_id.should be_nil
      user.destroy
      Audited.audit_class.where(:auditable_type => 'Models::ActiveRecord::User', :auditable_id => user.id, :action => 'destroy').first.transaction_id.should be_nil
    end
  end

  describe "audited_classes" do
    class Models::ActiveRecord::CustomUser < ::ActiveRecord::Base
    end
    class Models::ActiveRecord::CustomUserSubclass < Models::ActiveRecord::CustomUser
      audited
    end

    it "should include audited classes" do
      Audited.audit_class.audited_classes.should include(Models::ActiveRecord::User)
    end

    it "should include subclasses" do
      Audited.audit_class.audited_classes.should include(Models::ActiveRecord::CustomUserSubclass)
    end
  end

  describe "new_attributes" do

    it "should return a hash of the new values" do
      Audited.audit_class.new(:audited_changes => {:a => [1, 2], :b => [3, 4]}).new_attributes.should == {'a' => 2, 'b' => 4}
    end

  end

  describe "old_attributes" do

    it "should return a hash of the old values" do
      Audited.audit_class.new(:audited_changes => {:a => [1, 2], :b => [3, 4]}).old_attributes.should == {'a' => 1, 'b' => 3}
    end

  end

  describe "with_transaction_id" do
    let(:tr) { SecureRandom.hex(32) }

    it "should record transaction ids" do
      Audited.audit_class.with_transaction_id(tr) do
        company = Models::ActiveRecord::Company.create :name => 'The auditors'
        company.name = 'The Auditors, Inc'
        company.save

        company.audits.each do |audit|
          audit.transaction_id.should == tr
        end
      end
    end

    it "should return the value from the yield block" do
      Audited.audit_class.with_transaction_id(tr) do
        tr
      end.should == tr
    end
  end

  describe "with_attributes" do
    let(:tr) { SecureRandom.hex(32) }
    let(:org) { 123 }

    it "should record transaction ids" do
      attributes = {
        :audited_transaction_id => tr,
        :audited_organization_id => org
      }
      Audited.audit_class.with_attributes(attributes) do
        company = Models::ActiveRecord::Company.create :name => 'The auditors'
        company.name = 'The Auditors, Inc'
        company.save

        company.audits.each do |audit|
          audit.transaction_id.should == tr
          audit.organization_id.should == org
        end
      end
    end

    it "should return the value from the yield block" do
      Audited.audit_class.with_transaction_id(tr) do
        tr
      end.should == tr
    end
  end

  describe "as_user" do

    it "should record user objects" do
      Audited.audit_class.as_user(user) do
        company = Models::ActiveRecord::Company.create :name => 'The auditors'
        company.name = 'The Auditors, Inc'
        company.save

        company.audits.each do |audit|
          audit.user.should == user
        end
      end
    end

    it "should record usernames" do
      Audited.audit_class.as_user(user.name) do
        company = Models::ActiveRecord::Company.create :name => 'The auditors'
        company.name = 'The Auditors, Inc'
        company.save

        company.audits.each do |audit|
          audit.username.should == user.name
        end
      end
    end

    it "should be thread safe" do
      begin
        t1 = Thread.new do
          Audited.audit_class.as_user(user) do
            sleep 1
            Models::ActiveRecord::Company.create(:name => 'The Auditors, Inc').audits.first.user.should == user
          end
        end

        t2 = Thread.new do
          Audited.audit_class.as_user(user.name) do
            Models::ActiveRecord::Company.create(:name => 'The Competing Auditors, LLC').audits.first.username.should == user.name
            sleep 0.5
          end
        end

        t1.join
        t2.join
      rescue ActiveRecord::StatementInvalid
        STDERR.puts "Thread safety tests cannot be run with SQLite"
      end
    end

    it "should return the value from the yield block" do
      Audited.audit_class.as_user('foo') do
        42
      end.should == 42
    end

  end

  describe "mass assignment" do
    it "should accept :action, :audited_changes and :comment attributes as well as the :associated association" do
      Audited.audit_class.accessible_attributes.should include(:action, :audited_changes, :comment, :associated)
    end
  end
end
