module Joinable #:nodoc:
  module ActsAsJoinableComponent
    module ActMethod
      # Inherits permissions of an a target object through the permission_links table
      # An entry in the permission_links table is calculated by tracing the proxy object through to the target
      # Takes a hash of params that specify which attached object the proxy should inherit its permissions from
      def acts_as_joinable_component(options = {})
        extend ClassMethods unless (class << self; included_modules; end).include?(ClassMethods)
        include InstanceMethods unless included_modules.include?(InstanceMethods)
        
        options.assert_valid_keys :polymorphic, :parent, :view_permission
        
        class << self
          attr_accessor :view_permission
        end

        self.view_permission = options[:view_permission]
        
        # If we inherit permissions from multiple types of objects (polymorphic)
        if options[:polymorphic]
          parent_klass = options[:parent] + '_type.constantize'
          parent_id = options[:parent] + '_id'
        # Else if we are not, and inherit permissions from only one type of object
        else
          parent_klass = options[:parent].camelize
          parent_id = options[:parent] + '_id'
        end
        
        # Rescue in case we haven't got a parent 
        # TODO: this could probably be done better
        class_eval <<-EOV
          def next_link
            begin
              #{parent_klass}.find_by_id(#{parent_id})
            rescue
              nil
            end
          end
        EOV
      end
    end

    module ClassMethods
      include Joinable::ActsAsPermissable::ClassMethods
  
      def self.extended(base)        
        base.has_one :permission_link, :as => :component, :dependent => :destroy
        base.after_create :find_joinable_and_create_permission_link
      end
  
      # Returns the SQL necessary to find all components for which there is no associated joinable or 
      # the user has a membership with a specific permission.
      # 
      # Permissions which require special handling:
      #
      # * view_* - This is a class of permissions that start with the word 'view'. When determining if a user can view any aspect of a joinable, we also check
      #            if the project is open.
      #
      # * join_and_* - This is a class of permissions that start with the words 'join_and_'. When determining if a user will have a certain permission
      #                after they join a project, we need to check the default_permission_set of the project.
      def with_permission_sql(user, permission, options = {})
        permission = permission.to_s
        user_id = user.respond_to?(:id) ? user.id : user # Support objects that aren't ActiveRecord::Base but respond to id
        component_id_column = options[:id_column] || "#{table_name}.id"
        permission_without_join_and_prefix = permission.gsub('join_and_', '')
        permission_or_column = permission_without_join_and_prefix == 'view' ? "permission_links.component_view_permission" : "'#{permission_without_join_and_prefix}'"

        if permission.starts_with?('view')
          "#{no_inherited_permissions_exist_sql(component_id_column)} OR #{membership_permission_exists_sql(user_id, component_id_column, permission_or_column)} OR #{default_permission_set_permission_exists_sql(component_id_column, permission_or_column)}"
        elsif permission.starts_with?('join_and_')
          default_permission_set_permission_exists_sql(component_id_column, permission_or_column)
        else
          "#{no_inherited_permissions_exist_sql(component_id_column)} OR #{membership_permission_exists_sql(user_id, component_id_column, permission_or_column)}"
        end
      end
  
      private
  
      # All components that don't have a permission link to a joinable
      def no_inherited_permissions_exist_sql(component_id_column)
        permission_links_for_joinable = PermissionLink.where(:component_type => self.name).where("permission_links.component_id = #{component_id_column}")

        return "NOT EXISTS (#{ permission_links_for_joinable.to_sql })"
      end
  
      # All components that have an associated membership with a specific permission
      #
      # The view permission requires special handling because it may be customized in the permission_link.
      # For more information see the *recurse_to_inherit_custom_view_permission* method.
      def membership_permission_exists_sql(user_id, component_id_column, permission_or_column)
        memberships_allowing_permission = Membership.joins(:permission_links)
          .where("user_id = #{user_id}")
          .where("permission_links.component_type" => self.name)
          .where("permission_links.component_id = #{component_id_column}")
          .where(permission_sql_condition('memberships.permissions', permission_or_column, :raw => true))
        
        return "EXISTS (#{ memberships_allowing_permission.to_sql })"
      end

      def default_permission_set_permission_exists_sql(component_id_column, permission_or_column)
        sets_allowing_permission = DefaultPermissionSet.joins(:permission_links)
          .where("permission_links.component_type" => self.name)
          .where("permission_links.component_id = #{component_id_column}")
          .where(permission_sql_condition('default_permission_sets.permissions', permission_or_column, :raw => true))

        return "EXISTS (#{ sets_allowing_permission.to_sql })"
      end
    end

    module InstanceMethods
      include Joinable::ActsAsPermissable::InstanceMethods

      def acts_like_joinable_component?
        true
      end
      
      # Used by unsaved joinable_components to return a list of users
      # who will be able to view the component once it is saved.
      # Useful for outputting information to the user while they 
      # are creating a new component.
      def who_will_be_able_to_view?
        User.joins(:memberships)
          .where(:memberships => {:joinable => joinable})
          .where(permission_sql_condition('memberships.permissions', recurse_to_inherit_custom_view_permission))
      end

      def check_permission(user, permission)
        # You can't ask to join joinable_components so the find permission is actually the view permission
        permission = :view if permission == :find
        
        if new_record?
          if joinable.acts_like?(:joinable)
            permission = recurse_to_inherit_custom_view_permission if permission == :view
            joinable.check_permission(user, permission)
          else
            # The component isn't contained by a joinable so it is public.
            true
          end
        else
          self.class.with_permission(user, permission).exists?(id)
        end
      end
  
      # Returns the object that we should inherit permissions from
      #
      # Recurses until the target is reached, 
      # if we reach a target that does not act as a joinable, call method again if it is a joinable component, 
      # else fall out as the chain has no valid endpoint (eg. feed -> discussion -> item)
      def joinable
        if permission_link.present?
          permission_link.joinable
        else
          parent = next_link
          
          # Our target is now joinable therefore our target is at the end (eg. feed -> discussion -> [project])
          if parent && parent.acts_like?(:joinable)
            return parent

          # Our target is a joinable_component therefore our target somewhere between the beginning and the end (eg. feed -> [discussion] -> ??? -> project)
          elsif parent && parent.acts_like?(:joinable_component)
            return parent.joinable

          # We've fallen out because there was either no target or the target was not joinable or a joinable_component
          else
            return parent
          end
        end
      end

      # inherited_view_permission is calculated by ascending up the chain of joinable components
      # while view permission only takes into account the current joinable component.
      # inherited_view_permission is for external use while view_permission should only be used internally.
      def inherited_view_permission
        permission_link.try(:component_view_permission)
      end

      def view_permission
        klass_view_permission = self.class.view_permission
        klass_view_permission = klass_view_permission.call(self) if klass_view_permission.respond_to?(:call)

        # Allow view_permission to be set at the instance level
        return @view_permission || klass_view_permission
      end
      attr_writer :view_permission

      private

      # Recurse up the tree to see if any of the intervening joinable_components have a customized view permission
      # In that case, inherit that customized view permission. This allows searches of the form
      # Feed.with_permission(:view) where feeds belong to joinable_components with custom view permissions.
      # The query will then be able to return only the feeds which belong to joinable components that are viewable by the user
      def recurse_to_inherit_custom_view_permission
        parent = next_link

        # If we've reached the last component in the chain or if this component provides a view permission
        if parent.acts_like?(:joinable) || self.view_permission
          return self.view_permission || :view
        elsif parent.acts_like?(:joinable_component)
          return parent.send(:recurse_to_inherit_custom_view_permission)
        else
          return nil
        end
      end

      # Creates a link to the joinable that this component is associated with, if there is one.
      def find_joinable_and_create_permission_link
        self.create_permission_link(:joinable => joinable, :component_view_permission => recurse_to_inherit_custom_view_permission) if joinable.acts_like?(:joinable)
      end
    end
  end
end