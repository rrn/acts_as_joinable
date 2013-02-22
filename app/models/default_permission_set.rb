class DefaultPermissionSet < ActiveRecord::Base
  include Joinable::PermissionsAttributeWrapper
    
	belongs_to :joinable, :polymorphic => true

  after_update :raise_existing_member_permissions
  
  def access_model
    if has_permission?(:view)
      return 'open'
    elsif has_permission?(:find)
      return 'closed'
    else
      return 'private'
    end
  end
  
  def access_model=(model)
    case model.to_s
    when 'open'
      # Additional permissions are set explicitly so just grant the find and view permissions
      self.grant_permissions([:find, :view])
    when 'closed'
      self.permissions = [:find]
    when 'private'
      self.permissions = []
    else
      raise "Access model invalid: #{model}"
    end
  end

  private

  def raise_existing_member_permissions
    (joinable.memberships + joinable.membership_invitations).each do |membership|
      membership.permissions = membership.permissions + permissions
      membership.save!
    end
  end
end