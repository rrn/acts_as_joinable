class Feed < ActiveRecord::Base
  acts_as_joinable_component :parent => 'permission_inheritance_target', :polymorphic => true, :view_permission => lambda {|feed| :find if feed.feedable.acts_like?(:joinable) }
  
  # The feed may have been delegated (or the feedable may have been deleted) so inherit permissions from scoping_object
  # eg. a user (non-permissible) leaves a project, the permission to view the feed rests with the project because the feedable is the user itself
  def permission_inheritance_target_type
    if feedable.acts_like?(:permissable)
      feedable_type
    else
      scoping_object_type
    end
  end
  
  def permission_inheritance_target_id
    if feedable.acts_like?(:permissable)
      feedable_id
    else
      scoping_object_id
    end
  end
end