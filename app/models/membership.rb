class Membership < ActiveRecord::Base  
  include Joinable::PermissionsAttributeWrapper

  belongs_to :joinable, :polymorphic => true
  belongs_to :user

  before_save :prevent_locked_permission_changes, :normalize_owner_permissions
  before_destroy :ensure_feed_creation

  validates_presence_of :user_id
  validates_uniqueness_of :user_id, :scope => [:joinable_type, :joinable_id] # Ensure that a User has only one Membership per Joinable
  after_create :destroy_remnant_invitations_and_requests

  acts_as_feedable :parent => 'joinable', :delegate => {:references => 'user', :actions => {:created => 'joined', :destroyed => 'left'}}

  attr_accessor :initiator, :locked
  
  
  def locked?
    locked == 'true'
  end
  
  def owner?
    user == joinable.user
  end

  def permissions_locked?(current_user)
    # Don't allow any changes to your own permissions
    if current_user.eql?(user)
      return true
    # Don't allow any changes to the owner's permissions  
    elsif owner?
      return true
    else
      return false
    end
  end
  
  private
  
  def ensure_feed_creation
    with_feed(initiator) if initiator.present?
  end

  def prevent_locked_permission_changes
    reload if locked?
  end
  
  def normalize_owner_permissions
    if owner?
      self.permissions = joinable_type.constantize.permissions
    else
      self.permissions = permissions.reject {|level| level == :own}
    end
  end

  def destroy_remnant_invitations_and_requests
    # Make sure invitation is the first to be destroyed, for feed purposes.
    if invitation = joinable.membership_invitation_for(user)
      invitation.destroy
    end

    if request = joinable.membership_request_for(user)
      request.destroy
    end
  end
end