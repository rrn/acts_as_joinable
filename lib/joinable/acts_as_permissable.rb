# Abstract Module that is included in both joinable and joinable_component. Includes useful methods that both share.
module Joinable #:nodoc:
  module ActsAsPermissable
    module ClassMethods
  		def find_with_privacy(record_id, user, options = {})
  			record = find(record_id)
			
  			raise ActiveRecord::RecordNotFound, (options[:error_message] || "Couldn't find #{name}") unless user.permission_to?(:find, record)
		
  		  return record
  		end
  		
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
        User.find_by_sql("SELECT * FROM users AS u1 WHERE #{self.class.with_permission_sql('u1.id', permission, :id_column => id)}")
      end
    end
  end
end