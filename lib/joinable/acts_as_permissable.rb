# Abstract Module that is included in both joinable and joinable_component. Includes useful methods that both share.
module Joinable #:nodoc:
  module ActsAsPermissable
    module ClassMethods
  		def find_with_privacy(record_id, user, options = {})
  			record = find(record_id)
			
  			raise ActiveRecord::RecordNotFound, (options[:error_message] || "Couldn't find #{name}") unless user.permission_to?(:find, record)
		
  		  return record
  		end
  		
      # Returns all records where the given user has the given permission
      def with_permission(user, permission)
        select("#{table_name}.*").where(with_permission_sql(user, permission))
      end

      # Returns an SQL fragment for a WHERE condition that evaluates to true if the user has the given permission
      # For use when asking 
      def with_permission_sql(user, permission, options = {})
        raise NotImplementedError
      end

      # Returns an SQL fragment for a WHERE condition that checks the given column for the given permission
      def permission_sql_condition(column, permission)
        "'#{permission}' = ANY(#{column})"
      end
    end

    module InstanceMethods
      def acts_like_permissable?
        true
      end
    
      # Returns a list of users who either do or do not have the specified permission.
      def who_can?(permission)
        User.where(self.class.with_permission_sql("#{User.table_name}.id", permission, :id_column => id))
      end

      delegate :with_permission_sql, :permission_sql_condition, :to => 'self.class'
    end
  end
end