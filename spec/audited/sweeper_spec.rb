require "spec_helper"

class AuditsController < ActionController::Base
  attr_reader :company

  def create
    @company = Models::ActiveRecord::Company.create
    head :ok
  end

  def update
    current_user.update_attributes(password: 'foo')
    head :ok
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

describe AuditsController do
  include RSpec::Rails::ControllerExampleGroup
  render_views

  before(:each) do
    Audited.current_user_method = :current_user
    Audited.organization_id_method = :organization_id
    Audited.transaction_id_method = :transaction_id
  end

  let(:user) { create_user }

  describe "POST audit" do

    it "should audit transation id" do
      controller.send(:transaction_id=, '123abc')

      post :audit
      expect(assigns(:company).audits.last.transaction_id).to eq('123abc')
    end

    it "should audit user" do
      controller.send(:current_user=, user)
      expect {
        post :create
      }.to change( Audited::Audit, :count )

      expect(controller.company.audits.last.user).to eq(user)
    end

    it "should audit organization" do
      controller.send(:organization_id=, 4)
      post :audit
      expect(assigns(:company).audits.last.organization_id).to eq(4)
    end

    it "should support custom users for sweepers" do
      controller.send(:custom_user=, user)
      Audited.current_user_method = :custom_user

      expect {
        post :create
      }.to change( Audited::Audit, :count )

      expect(controller.company.audits.last.user).to eq(user)
    end

    it "should record the remote address responsible for the change" do
      request.env['REMOTE_ADDR'] = "1.2.3.4"
      controller.send(:current_user=, user)

      post :create

      expect(controller.company.audits.last.remote_address).to eq('1.2.3.4')
    end

    it "should record a UUID for the web request responsible for the change" do
      allow_any_instance_of(ActionDispatch::Request).to receive(:uuid).and_return("abc123")
      controller.send(:current_user=, user)

      post :create

      expect(controller.company.audits.last.request_uuid).to eq("abc123")
    end

  end

  describe "POST with transaction id" do
    it "should work with a custom transaction id" do
      controller.send(:current_user=, user)
      controller.send(:transaction_id=, '123abc')

      post :update_with_transaction_id

      expect(assigns(:company).audits.last.transaction_id).to eq('customtransaction')
    end
  end

  describe "PUT update" do

    it "should not save blank audits" do
      controller.send(:current_user=, user)

      expect {
        put :update, id: 123
      }.to_not change( Audited::Audit, :count )
    end
  end
end


describe Audited::Sweeper do

  it "should be thread-safe" do
    t1 = Thread.new do
      sleep 0.5
      Audited::Sweeper.instance.controller = 'thread1 controller instance'
      expect(Audited::Sweeper.instance.controller).to eq('thread1 controller instance')
    end

    t2 = Thread.new do
      Audited::Sweeper.instance.controller = 'thread2 controller instance'
      sleep 1
      expect(Audited::Sweeper.instance.controller).to eq('thread2 controller instance')
    end

    t1.join; t2.join

    expect(Audited::Sweeper.instance.controller).to be_nil
  end

end
