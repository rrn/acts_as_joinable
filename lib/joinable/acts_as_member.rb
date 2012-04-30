# Adds useful methods to the User model which includes it.
module Joinable #:nodoc:
  module ActsAsMember  
    module ActMethod
      def acts_as_member
        extend ClassMethods unless (class << self; included_modules; end).include?(ClassMethods)
        include InstanceMethods unless included_modules.include?(InstanceMethods)
      end
    end

    module ClassMethods
      def self.extended(base)
        base.has_many :memberships, :dependent => :destroy
        base.has_many :membership_requests, :dependent => :destroy
        base.has_many :membership_invitations, :dependent => :destroy
      end
    end

    module InstanceMethods
      # FIXME: no need to call permission_to? on non-permissables. 
      # We should remove this extra code.
      def permission_to?(permission, record)
        if record.acts_like?(:permissable)
          record.check_permission(self, permission)
        else
          if record.acts_like?(:visible_only_to_owner)
            record.user == self
          else
            true
          end
        end
      end
    
      def no_permission_to?(permission, record)
        !permission_to?(permission, record)
      end
    
      def membership_requests_for_managed_projects
        MembershipRequest.for(self)
      end
    end
  end
end