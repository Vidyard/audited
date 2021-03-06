require File.expand_path('../active_record_spec_helper', __FILE__)

class AuditsController < ActionController::Base
  def audit
    @company = Models::ActiveRecord::Company.create
    render :nothing => true
  end

  def update_user
    current_user.update_attributes( :password => 'foo')
    render :nothing => true
  end

  def update_with_transaction_id
    Audited.audit_class.with_transaction_id('customtransaction') do
      @company = Models::ActiveRecord::Company.create
    end
    render :nothing => true
  end

  private

  attr_accessor :current_user
  attr_accessor :custom_user
  attr_accessor :transaction_id
  attr_accessor :organization_id
end

describe AuditsController, :adapter => :active_record do
  include RSpec::Rails::ControllerExampleGroup

  before(:each) do
    Audited.current_user_method = :current_user
    Audited.organization_id_method = :organization_id
    Audited.transaction_id_method = :transaction_id
  end

  let( :user ) { create_user }

  describe "POST audit" do

    it "should audit transation id" do
      controller.send(:transaction_id=, '123abc')

      post :audit
      assigns(:company).audits.last.transaction_id.should eq('123abc')
    end

    it "should audit user" do
      controller.send(:current_user=, user)

      expect {
        post :audit
      }.to change( Audited.audit_class, :count )

      assigns(:company).audits.last.user.should == user
    end

    it "should audit organization" do
      controller.send(:organization_id=, 4)
      post :audit
      assigns(:company).audits.last.organization_id.should eq(4)
    end

    it "should support custom users for sweepers" do
      controller.send(:custom_user=, user)
      Audited.current_user_method = :custom_user

      expect {
        post :audit
      }.to change( Audited.audit_class, :count )

      assigns(:company).audits.last.user.should == user
    end

    it "should record the remote address responsible for the change" do
      request.env['REMOTE_ADDR'] = "1.2.3.4"
      controller.send(:current_user=, user)

      post :audit

      assigns(:company).audits.last.remote_address.should == '1.2.3.4'
    end

  end

  describe "POST withtransaction id" do
    it "should work with a custom transaction id" do
      controller.send(:current_user=, user)
      controller.send(:transaction_id=, '123abc')

      post :update_with_transaction_id

      assigns(:company).audits.last.transaction_id.should eq('customtransaction')
    end
  end

  describe "POST update_user" do

    it "should not save blank audits" do
      controller.send(:current_user=, user)

      expect {
        post :update_user
      }.to_not change( Audited.audit_class, :count )
    end

  end
end
