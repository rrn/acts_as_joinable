require 'test_helper'

class PermissionTest < ActiveSupport::TestCase
  test "Model with custom view_permission generates the correct PermissionLink" do
    project = Project.create!(:default_permission_set_attributes => {:access_model => "closed"}, :user => current_user)
    discussion = Discussion.create!(:discussable => project)

    equal discussion.permission_link.component_view_permission.to_s, 'view_discussions'
  end
end