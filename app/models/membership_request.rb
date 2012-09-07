class MembershipRequest < ActiveRecord::Base
  belongs_to :joinable, :polymorphic => true
  belongs_to :user
  
  validates_presence_of :user_id
  validates_uniqueness_of :user_id, :scope => [:joinable_type, :joinable_id]
  
  scope :for, lambda {|user|
    joins("INNER JOIN memberships ON membership_requests.joinable_type = memberships.joinable_type AND membership_requests.joinable_id = memberships.joinable_id")
    .where("memberships.user_id = ? AND memberships.permissions ~ ?", user.id, '\\mmanage\\M')
  }
  
  after_create :match_to_invitation_or_send_email
  
  def grant(current_user, permissions)
    membership = create_associated_membership_on_grant(current_user, permissions)
    UserMailer.project_membership_request_accepted_email(current_user, membership).deliver
  end

  private

  def create_associated_membership_on_grant(current_user, permissions)
    Membership.create(:joinable => joinable, :user => user, :permissions => permissions)
  end

  # If a user requests to join a joinable, make sure their isn't a matching invitation
  # to join the joinable. If there is, then automatically accept the user into the joinable.
  # Otherwise notify the managers of the project that their is a new request.
  def match_to_invitation_or_send_email
    if invitation = joinable.membership_invitation_for(user)
      invitation.accept(invitation.user)
    else
      UserMailer.project_membership_request_created_email(joinable.who_can?(:manage), self).deliver
    end
  end
end