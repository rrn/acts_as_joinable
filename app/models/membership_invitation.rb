class MembershipInvitation < ActiveRecord::Base
  include Joinable::PermissionsAttributeWrapper
  
  belongs_to :joinable, :polymorphic => true
  belongs_to :user
  belongs_to :initiator, :class_name => "User"
  validates_presence_of :user_id
  validates_uniqueness_of :user_id, :scope => [:joinable_type, :joinable_id]

  after_create :match_to_request_or_send_email
  
  def accept(current_user)
    return false unless current_user == user
    create_associated_membership_on_accept(current_user)
  end
  
  def decline(current_user)
    return false unless current_user == user
    destroy_self_on_decline(current_user)
  end

  private

  def create_associated_membership_on_accept(current_user)
    Membership.create(:joinable => joinable, :user => user, :permissions => permissions)
  end

  def destroy_self_on_decline(current_user)
    destroy
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