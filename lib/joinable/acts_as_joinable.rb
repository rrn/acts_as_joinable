module Joinable #:nodoc:
  module ActsAsJoinable
    module ActMethod
      # Takes one option :component_permissions - a list of all of the permissions grouped by the component they affect
      # eg. [{:labels => [:view, :apply, :remove, :create, :delete]}]
      #
      # The grouped permissions are unpacked to create distinct permissions (eg. view_labels, apply_labels, ...)
      # These unpacked permissions are put into an array with the singular permissions (eg. find)
      # and stored in a *permissions* class variable.
      #
      # In addition, The grouped permissions are stored in a separate *component_permissions_hash* class variable.
      # 
      # NOTE: The permissions are passed in-order because in the view we expect to find certain permission patterns.
      #       eg. the simple project permission level is determined by looking for a string of permissions that span
      #       several components, (labels, writeboards, files, etc...).
      # TODO: Remove the aforementioned order dependency      
      def acts_as_joinable(options = {})
        extend ClassMethods
        include InstanceMethods

        options.assert_valid_keys :component_permissions
        self.component_permissions_hash = options[:component_permissions]

        self.permissions = [:find, :view]
        add_flattened_component_permissions(options[:component_permissions])
        self.permissions += [:manage, :own]
      end

      private

      # Add explicit permissions to the permissions class accessor
      # for each of the entries in the component_permission hashes
      #
      # eg. {:labels => [:view, :apply, :remove, :create, :delete]} becomes
      #      [:view_labels, :apply_labels, :remove_labels, :create_labels, :delete_labels]
      #      and is added to self.permissions
      def add_flattened_component_permissions(component_permissions_hash)
        component_permissions_hash.each do |component_name, component_permissions|
          component_permissions.each { |component_permission| self.permissions << "#{component_permission}_#{component_name}".to_sym }
        end
      end
    end

    module ClassMethods
      include Joinable::ActsAsPermissable::ClassMethods

      def self.extended(base)
        base.class_eval do
          cattr_accessor :permissions, :component_permissions_hash

          has_many :membership_invitations,   :as => :joinable, :dependent => :destroy, :before_add => :add_initiator
          has_many :membership_requests,      :as => :joinable, :dependent => :destroy
          has_many :memberships,              lambda { order :id }, :as => :joinable, :dependent => :destroy, :before_remove => :add_initiator

          has_many :invitees,                 :class_name => "User", :through => :membership_invitations, :source => :user
          has_many :requestees,               :class_name => "User", :through => :membership_requests, :source => :user
          has_many :members,                  :class_name => "User", :through => :memberships, :source => :user

          has_many :permission_links,         :as => :joinable, :dependent => :destroy
          has_one :default_permission_set,    :as => :joinable, :dependent => :destroy
                  
          scope :with_member,                 lambda {|user| joins(:memberships).where(:memberships => {:user_id => user}).order("memberships.created_at DESC") }

          accepts_nested_attributes_for :default_permission_set
          accepts_nested_attributes_for :membership_invitations, :allow_destroy => true
          accepts_nested_attributes_for :memberships, :allow_destroy => true, :reject_if => proc { |attributes| attributes['locked'] == 'true' }

          after_create :add_owner_membership        
        end
      end

      def permissions_string
        permissions.join(" ")
      end

      # Simple Permission Strings - Permission strings for four basic levels of permissions - viewer, collaborator, manager, owner
      # =============================================
      # Member can view everything but modify nothing
      def viewer_permissions_string
        viewer_permissions.join(" ")
      end

      def viewer_permissions
        permissions.select { |permission| permission == :find || permission.to_s.starts_with?("view") }
      end

      # Member can view everything and modify everything except members
      def collaborator_permissions_string
        collaborator_permissions.join(" ")
      end

      def collaborator_permissions
        permissions - [:manage, :own]
      end

      # Member can view everything, modify everything, and manage membership
      def manager_permissions_string
        (permissions - [:own]).join(" ")
      end

      # Member started the joinable
      def owner_permissions_string
        permissions_string
      end
      # =============================
      # End Simple Permission Strings

      # Returns the SQL necessary to find all joinables for which the user
      # has a membership with a specific permission.
      # 
      # Permissions which require special handling:
      #
      # * find - In addition to memberships, invitations and default permission sets are checked for the permission. This is because
      #          a joinable should be able to be found once an invitation has been extended or if it is findable by default. (even if the user isn't a member of it).
      #
      # * view_* - This is a class of permissions that start with the word 'view'. When determining if a user can view any aspect of a joinable, we also check
      #            if the project is open.
      #
      # * join - This is a faux permission. A user has permission to join a joinable if they have an invitation to view it or if it is viewable by default.
      #
      # * collaborate - This is a faux permission. A user has permission to collaborate if they have any additional permissions above the standard viewer permissions.
      def with_permission_sql(user, permission, options = {})
        permission = permission.to_sym

        case user
        when String
          user_id = user
        when
          user_id = user.id
        end

        joinable_type = options[:type_column] || name
        joinable_id = options[:id_column] || table_name + ".id"

        if permission == :find
          "#{membership_permission_exists_sql(user_id, joinable_type, joinable_id, 'find')} OR #{membership_invitation_permission_exists_sql(user_id, joinable_type, joinable_id, 'find')} OR #{default_permission_set_permission_exists_sql(joinable_type, joinable_id, 'find')}"
        elsif permission.to_s.starts_with?('view')
          "#{membership_permission_exists_sql(user_id, joinable_type, joinable_id, permission)} OR #{default_permission_set_permission_exists_sql(joinable_type, joinable_id, permission)}"
        elsif permission == :join
          "#{membership_invitation_permission_exists_sql(user_id, joinable_type, joinable_id, 'view')} OR #{default_permission_set_permission_exists_sql(joinable_type, joinable_id, 'view')}"
        elsif permission.to_s.starts_with?('join_and_')
          default_permission_set_permission_exists_sql(joinable_type, joinable_id, permission.to_s.gsub('join_and_', ''))
        elsif permission == :collaborate
          "EXISTS (SELECT id FROM memberships WHERE memberships.joinable_type = '#{joinable_type}' AND memberships.joinable_id = #{joinable_id} AND memberships.user_id = #{user_id} AND memberships.permissions && '{#{(collaborator_permissions - viewer_permissions).join(",")}}')"
        else
          membership_permission_exists_sql(user_id, joinable_type, joinable_id, permission)
        end
      end

      private

      def membership_permission_exists_sql(user_id, joinable_type, joinable_id, permission)
        "EXISTS (SELECT id FROM memberships WHERE memberships.joinable_type = '#{joinable_type}' AND memberships.joinable_id = #{joinable_id} AND memberships.user_id = #{user_id} AND #{permission_sql_condition('memberships.permissions', permission)})"
      end

      def membership_invitation_permission_exists_sql(user_id, joinable_type, joinable_id, permission)
        "EXISTS (SELECT id FROM membership_invitations WHERE membership_invitations.joinable_type = '#{joinable_type}' AND membership_invitations.joinable_id = #{joinable_id} AND membership_invitations.user_id = #{user_id} AND #{permission_sql_condition('membership_invitations.permissions', permission)})"
      end

      def default_permission_set_permission_exists_sql(joinable_type, joinable_id, permission)
        "EXISTS (SELECT id FROM default_permission_sets WHERE default_permission_sets.joinable_type = '#{joinable_type}' AND default_permission_sets.joinable_id = #{joinable_id} AND #{permission_sql_condition('default_permission_sets.permissions', permission)})"
      end
    end

    module InstanceMethods
      include Joinable::ActsAsPermissable::InstanceMethods

      # Override attributes= to make sure that the user and initiator attributes are initialized before
      # the membership_invitation and membership before_add callbacks are triggered
      # since they reference these attributes
      def attributes=(attributes_hash)
        super(ActiveSupport::OrderedHash[attributes_hash.symbolize_keys.sort_by {|a| [:user, :user_id, :initiator].include?(a.first) ? 0 : 1}])
      end
      
      def acts_like_joinable?
        true
      end

      attr_accessor :cached_membership_request, :cached_membership_invitation, :cached_membership, :initiator

      # Get the membership request (if any) for a specific
      # user. This method also supports caching of a membership
      # request in order to facilitate eager loading.
      #
      # eg. For all of the projects on the projects index page,
      # we want to do something similar to
      # Project.all(:include => :membership_requests).
      #
      # We can't do exactly that however because we only want the membership_requests
      # related to the current_user, not all users.
      #
      # Instead, we fake it by doing a separate query
      # which gets all the user's membership_requests related to
      # all the projects being displayed. We then cache the request relevant to
      # this project in the cached_membership_request instance variable for later use
      # by the view.
      def membership_request_for(user)
        if cached_membership_request != nil
          cached_membership_request
        else
          membership_requests.where(:user_id => user.id).first
        end
      end

      # Find out whether this Joinable has a membership request for a certain user and return true, else false
      def membership_request_for?(user)
        !membership_request_for(user).nil?
      end


      # Get the membership invitation (if any) for a specific
      # user. This method also supports caching of a membership
      # request in order to facilitate eager loading.
      #NOTE: See :membership_request_for documentation for an in depth example of this type of behaviour
      def membership_invitation_for(user)
        if cached_membership_invitation != nil
          cached_membership_invitation
        else
          membership_invitations.where(:user_id => user.id).first
        end
      end
      
      # Find out whether this Joinable has a membership invitation for a certain user and return true, else false
      def membership_invitation_for?(user)
        !membership_invitation_for(user).nil?
      end

      # Get the membership (if any) for a specific
      # user. This method also supports caching of a membership
      # request in order to facilitate eager loading.
      #NOTE: See :membership_request_for documentation for an in depth example of this type of behaviour
      def membership_for(user_id)
        if cached_membership != nil
          cached_membership
        else
          memberships.where(:user_id => user_id).first
        end
      end

      # Find out whether this Joinable has a membership for a certain user and return true, else false
      def membership_for?(user_id)
        !membership_for(user_id).nil?
      end

      # Returns the timestamp of the last time the memberships were updated for this joinable
      def memberships_updated_at
        memberships.maximum(:updated_at)
      end

      delegate :access_model, :to => :default_permission_set

      def access_model=(model)
        default_permission_set.access_model = model
      end

      # Returns true or false depending on whether or not the user has the specified permission for this object.
      # Will cache the result if uncached.
      def check_permission(user, permission_name)
        permission_name = permission_name.to_s.dup

        # Generate a cache path based on the factors that affect the user's permissions
        # If User has membership
        #  - depends on permissions
        # Elsif User has been invited
        #  - depends on existence of invitation and the default permissions (when checking the view permission)
        # Else User doesn't have any membership
        #  - depends on default permissions of the joinable
        if membership = memberships.where(:user_id => user.id).first
          key = "membership_#{membership.updated_at.to_f}"
        elsif self.membership_invitations.where(:user_id => user.id).exists?
          key = "default_permissions_#{self.default_permission_set.updated_at.to_f}_invitation_exists"
        else
          key = "default_permissions_#{self.default_permission_set.updated_at.to_f}"
        end

        cache_path = "permissions/#{self.class.table_name}/#{self.id}/user_#{user.id}_#{key}"

        if defined?(Rails.cache)
          permissions = Rails.cache.read(cache_path)
          if permissions && (value = permissions[permission_name]) != nil
            return value
          end
        end

        # The permission isn't cached yet, so cache it
        value = self.class.with_permission(user, permission_name).exists?(self.id)

        if defined?(Rails.cache)
          if permissions
            permissions = permissions.dup
            permissions[permission_name] = value
          else
            permissions = {permission_name => value}
          end
          Rails.cache.write(cache_path, permissions)
        end
        return value
      end

      private

      # Adds an initiator to a membership or invitation to possibly use in feed generation
      def add_initiator(membership)
        membership.initiator = (initiator || user)
      end

      # Adds an permission entry with full access to the object by the user associated with the object if one does not already exist
      def add_owner_membership
       Membership.create(:joinable => self, :user => user, :permissions => self.class.permissions_string) unless Membership.where(:joinable_type => self.class.to_s, :joinable_id => self.id, :user_id => user.id).exists?
      end
    end
  end
end
