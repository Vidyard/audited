require 'set'

module Audited
  # Audit saves the changes to ActiveRecord models.  It has the following attributes:
  #
  # * <tt>auditable</tt>: the ActiveRecord model that was changed
  # * <tt>user</tt>: the user that performed the change; a string or an ActiveRecord model
  # * <tt>action</tt>: one of create, update, or delete
  # * <tt>audited_changes</tt>: a serialized hash of all the changes
  # * <tt>comment</tt>: a comment set with the audit
  # * <tt>version</tt>: the version of the model
  # * <tt>request_uuid</tt>: a uuid based that allows audits from the same controller request
  # * <tt>created_at</tt>: Time that the change was performed
  #
  class Audit < ::ActiveRecord::Base
    include ActiveModel::Observing

    belongs_to :auditable,  polymorphic: true
    belongs_to :user,       polymorphic: true
    belongs_to :associated, polymorphic: true

    before_create :set_audit_user, :set_request_uuid, :set_transaction_id, :set_attributes

    cattr_accessor :audited_class_names
    self.audited_class_names = Set.new

    serialize :audited_changes

    scope :creates,       ->{ where(action: 'create')}
    scope :updates,       ->{ where(action: 'update')}
    scope :destroys,      ->{ where(action: 'destroy')}

    # Returns a hash of the changed attributes with the new values
    def new_attributes
      (audited_changes || {}).inject({}.with_indifferent_access) do |attrs, (attr, values)|
        attrs[attr] = values.is_a?(Array) ? values.last : values
        attrs
      end
    end

    # Returns a hash of the changed attributes with the old values
    def old_attributes
      (audited_changes || {}).inject({}.with_indifferent_access) do |attrs, (attr, values)|
        attrs[attr] = Array(values).first

        attrs
      end
    end

    # Allows user to be set to either a string or an ActiveRecord object
    # @private
    def user_as_string=(user)
      # reset both either way
      self.user_as_model = self.username = nil
      user.is_a?(::ActiveRecord::Base) ?
        self.user_as_model = user :
        self.username = user
    end
    alias_method :user_as_model=, :user=
    alias_method :user=, :user_as_string=

    # @private
    def user_as_string
      user_as_model || username
    end
    alias_method :user_as_model, :user
    alias_method :user, :user_as_string

    # Returns the list of classes that are being audited
    def self.audited_classes
      audited_class_names.map(&:constantize)
    end

    # All audits made during the block called will be recorded as made
    # by +user+. This method is hopefully threadsafe, making it ideal
    # for background operations that require audit information.
    def self.as_user(user, &block)
      Thread.current[:audited_user] = user
      yield
    ensure
      Thread.current[:audited_user] = nil
    end

    def self.with_transaction_id(transaction_id, &block)
      Thread.current[:audited_transaction_id] = transaction_id
      yieldval = yield
      Thread.current[:audited_transaction_id] = nil
      yieldval
    end

      # Override a bunch of values
    def self.with_attributes(hash, &block)
      hash.each do |key, value|
        Thread.current[key] = value
      end
      yieldval = yield
      hash.each do |key, value|
        Thread.current[key] = nil
      end
      yieldval
    end

    # use created_at as timestamp cache key
    def self.collection_cache_key(collection = all, timestamp_column = :created_at)
      super(collection, :created_at)
    end

    private

    def set_audit_user
      self.user = Thread.current[:audited_user] if Thread.current[:audited_user]
      nil # prevent stopping callback chains
    end

    def set_request_uuid
      self.request_uuid ||= SecureRandom.uuid
    end

    def set_attributes
      self.transaction_id = Thread.current[:audited_transaction_id] if Thread.current[:audited_transaction_id]
      self.organization_id = Thread.current[:audited_organization_id] if Thread.current[:audited_organization_id]
      nil
    end

    def set_transaction_id
      self.transaction_id = Thread.current[:audited_transaction_id] if Thread.current[:audited_transaction_id]
      nil
    end
  end
end
