# Included in models which have a permissions field (Membership, MembershipInvitation, DefaultPermissionSet)
# Wraps the permissions field to make it appear to the outside world as an array of symbols rather than the
# string that it is stored in the database as. Also adds helpers for creating complex forms 
# to configure permissions and validations to ensure consistent ordering of permissions in the database.
module Joinable #:nodoc:
  module PermissionsAttributeWrapper
    def self.included(base)
      base.before_save :verify_and_sort_permissions
    end
  
    def permissions_string
      self[:permissions].join(' ')
    end
  
    # Returns an array of the permissions as symbols
    def permissions
      self[:permissions].collect(&:to_sym)
    end
  
    def permissions=(permissions)
      case permissions
      when String
        self[:permissions] = permissions.split(' ')
      when Array
        self[:permissions] = permissions
      else
        raise "Permissions were not passed to permissions writer in the appropriate format"
      end
    end
  
    # Used by advanced permission forms which group permissions by their associated component
    # or using a single check box per permission.
    def permission_attributes=(permissions)
      self.permissions = [] # Reset permissions in anticipation for re-population
    
      permissions.each do |key, value|
        key, value = key.dup, value.dup
      
        # Component Permissions
        if key.ends_with? "_permissions"
          grant_permissions(value)
        # Singular Permission
        elsif key.chomp! "_permission"
          grant_permissions(key) if value.to_i != 0
        end
      end
    end
  
    # Returns an array of the permissions allowed by the joinable
    def allowed_permissions
      if self[:joinable_type]
        self[:joinable_type].constantize.permissions
      else
        raise "Cannot get allowed access levels because permission is not attached to a permissable yet: #{inspect}"
      end
    end

    # Returns true if the object has all the permissions specified by +levels+
    def has_permission?(*levels)
      if levels.all? { |level| permissions.include? level.to_sym }
        return true
      else
        return false
      end
    end

    # Returns true if none of the permissions specified by +levels+ are present
    def doesnt_have_permission?(*levels)
      if permissions - levels == permissions
        return true
      else
        return false
      end
    end

    # Returns true if the object has an empty permission set
    def no_permissions?
      permissions.empty?
    end

    # Returns true if the object only has the permissions in +levels+
    def only_permission_to?(*levels)
      if permissions - levels == []
        return true
      else
        return false
      end
    end
  
    def grant_permissions(permissions_to_grant)
      case permissions_to_grant
      when String
        permissions_to_grant = permissions_to_grant.split(' ').collect(&:to_sym)
      when Symbol
        permissions_to_grant = [permissions_to_grant]
      end
    
      self.permissions += permissions_to_grant
    end
  
    private
  
    # Verifies that all the access levels are valid for the attached permissible
    # Makes sure no permissions are duplicated
    # Enforces the order of access levels in the access attribute using the order of the permissions array
    def verify_and_sort_permissions
      # DefaultPermissionSet is allowed to have blank permissions (private joinable), the other models need at least find and view
      self.permissions += [:find, :view] unless is_a?(DefaultPermissionSet)
    
      raise "Invalid permissions: #{(permissions - allowed_permissions).inspect}. Must be one of #{allowed_permissions.inspect}" unless permissions.all? {|permission| allowed_permissions.include? permission}
    
      self.permissions = permissions.uniq.sort_by { |permission| allowed_permissions.index(permission) }
    end
  
    # Adds readers for component permission groups and single permissions
    #
    # Used by advanced permission forms to determine how which options to select
    # in the various fields. (eg. which option of f.select :labels_permissions to choose)
    def method_missing(method_name, *args)
      # add permission_for accessors and mutators
    
      # NOTE: Don't mess with the method_name variable (e.g. change it to a string)
      # since upstream methods might assume it is a symbol.
      # NOTE: Ensure we enforce some characters before the '_permission' suffix because Rails 3 creates 
      if respond_to?(:joinable_type) && joinable_type.present?
        if method_name.to_s =~ /.+_permissions/
          return component_permissions_reader(method_name)
        elsif method_name.to_s =~ /.+_permission/
          return single_permission_reader(method_name)
        else
          super
        end
      else
        super
      end
    end
  
    # Get a string of all of the permissions the object has for a specific joinable component
    # eg. labels_permissions # returns 'view_labels apply_labels remove_labels'
    def component_permissions_reader(method_name)
      joinable_type.constantize.component_permissions_hash.each do |component_name, component_permissions|
        if method_name.to_s == "#{component_name}_permissions"
          return component_permissions.collect {|permission| "#{permission}_#{component_name}"}.select {|permission| has_permission?(permission)}.join(" ")
        end
      end
    
      raise "Unknown component_permissions_reader #{method_name.inspect}"
    end
  
    # Access a single permission
    # eg. manage_permission # returns true if we can manage
    def single_permission_reader(method_name)
      for permission in joinable_type.constantize.permissions
        if method_name.to_s == "#{permission}_permission"
          return has_permission?(permission)
        end
      end
    
      raise "Unknown single_permission_reader #{method_name.inspect}"
    end
  end
end