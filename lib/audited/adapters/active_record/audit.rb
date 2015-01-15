require 'set'
require 'audited/audit'

module Audited
  module Adapters
    module ActiveRecord
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
        include Audited::Audit
        include ActiveModel::Observing

        serialize :audited_changes

        scope :creates,       ->{ where({:action => 'create'})}
        scope :updates,       ->{ where({:action => 'update'})}
        scope :destroys,      ->{ where({:action => 'destroy'})}

        scope :auditable_finder, ->(auditable_id, auditable_type){where(auditable_id: auditable_id, auditable_type: auditable_type)}
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
          self.user_as_model || self.username
        end
        alias_method :user_as_model, :user
        alias_method :user, :user_as_string
      end
    end
  end
end
