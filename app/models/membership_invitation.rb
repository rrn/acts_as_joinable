class MembershipInvitation < ActiveRecord::Base
  include Joinable::PermissionsAttributeWrapper
  
  belongs_to :joinable, :polymorphic => true
  belongs_to :user
  belongs_to :initiator, :class_name => "User"
  validates_presence_of :user_id
  validates_uniqueness_of :user_id, :scope => [:joinable_type, :joinable_id]

  before_create :ensure_feed_creation
  before_destroy :ensure_feed_creation

  after_create :match_to_request_or_send_email

  acts_as_feedable :parent => 'joinable', :delegate => {:references => 'user', :actions => {:created => 'invited', :destroyed => 'cancelled_invite'}}

  attr_accessor :no_default_feed
  
  def accept(current_user)
    return false unless current_user == user
    self.no_default_feed = true # Default feed has incorrect initiator. We're about to create a feed with the correct initiator.
    Membership.create_with_feed(user, :joinable => joinable, :user => user, :permissions => permissions)
  end
  
  def decline(current_user)
    return false unless current_user == user
    self.no_default_feed = true # Default feed has incorrect initiator. We're about to create a feed with the correct initiator.
    destroy_with_feed(user)
  end

  private
  
  # Don't create a destroyed feed if the user is accepting a membership invitation or a membership request exists for this User.
  # In that case, a membership was created, and this invitation should be 'invisible' to the Users and the UI. Thus no feeds should be created.
  def ensure_feed_creation
    with_feed(initiator) unless no_default_feed || joinable.membership_for?(user) || joinable.membership_request_for?(user)
  end

  # When a User has already made a request and then someone invites this User to join the Joinable
  # accept the invitation automatically on behalf of the user, otherwise notify the user
  # that they have an invite waiting.
  def match_to_request_or_send_email
    if joinable.membership_request_for?(user)
      accept(user)
    else
      UserMailer.invited_to_project_email(self).deliver
    end
  end
end