module Audited
  module Audit
    def self.included(klass)
      klass.extend(ClassMethods)
      klass.setup_audit
    end

    module ClassMethods
      def setup_audit
        belongs_to :auditable,    :polymorphic => true
        belongs_to :user,         :polymorphic => true
        belongs_to :associated,   :polymorphic => true

        before_create :set_audit_user
        before_create :set_transaction_id
        before_create :set_attributes

        cattr_accessor :audited_class_names
        self.audited_class_names = Set.new

        attr_accessible :action, :audited_changes, :comment, :associated, :transaction_id, :organization_id
      end

      # Returns the list of classes that are being audited
      def audited_classes
        audited_class_names.map(&:constantize)
      end

      # All audits made during the block called will be recorded as made
      # by +user+. This method is hopefully threadsafe, making it ideal
      # for background operations that require audit information.
      def as_user(user, &block)
        Thread.current[:audited_user] = user

        yieldval = yield

        Thread.current[:audited_user] = nil

        yieldval
      end

      def with_transaction_id(transaction_id, &block)
        Thread.current[:audited_transaction_id] = transaction_id
        yieldval = yield
        Thread.current[:audited_transaction_id] = nil
        yieldval
      end

      # Override a bunch of values
      def with_attributes(hash, &block)
        hash.each do |key, value|
          Thread.current[key] = value
        end
        yieldval = yield
        hash.each do |key, value|
          Thread.current[key] = nil
        end
        yieldval
      end

    end

    # Returns a hash of the changed attributes with the new values
    def new_attributes
      (audited_changes || {}).inject({}.with_indifferent_access) do |attrs,(attr,values)|
        attrs[attr] = values.is_a?(Array) ? values.last : values
        attrs
      end
    end

    # Returns a hash of the changed attributes with the old values
    def old_attributes
      (audited_changes || {}).inject({}.with_indifferent_access) do |attrs,(attr,values)|
        attrs[attr] = Array(values).first

        attrs
      end
    end

    private
    def set_audit_user
      self.user = Thread.current[:audited_user] if Thread.current[:audited_user]
      nil # prevent stopping callback chains
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
