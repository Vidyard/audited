module Audited
  VERSION = '3.0.0'

  class << self
    attr_accessor :ignored_attributes, :current_user_method, :transaction_id_method, :audit_class, :restoring, :organization_id_method
  end

  @ignored_attributes = %w(lock_version created_at updated_at created_on updated_on)

  @current_user_method = :current_user
  @organization_id_method = :organization_id
  @transaction_id_method = :transaction_id
  @restoring = false # When restoring, override all create actions to restore actions
end
