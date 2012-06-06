require 'test_helper'

class JoinableComponentTest < ActiveSupport::TestCase
  test "joinable_component with joinable parent generates PermissionLink" do    
    discussion = Discussion.create!(:discussable => closed_project)

    equal discussion.permission_link.component_view_permission.to_s, 'view'
  end

  test "joinable_component with non-permissable parent generates no PermissionLink" do
  	discussion = Discussion.create!

    equal discussion.permission_link, nil
  end

  test "joinable_component with custom view_permission generates the correct PermissionLink" do
    with_view_permission(Discussion, :view_discussions) do
    	discussion = Discussion.create!(:discussable => closed_project)

    	equal discussion.permission_link.component_view_permission.to_s, 'view_discussions'
    end
  end

  test "joinable_component with custom lambda view_permission generates the correct PermissionLink" do
  	with_view_permission(Discussion, lambda {|discussion| :view if discussion.discussable.is_a?(Project)}) do
    	discussion = Discussion.create!(:discussable => closed_project)

    	equal discussion.permission_link.component_view_permission.to_s, 'view'
  	end
  end

  test "joinable_component with custom instance level view_permission generates the correct PermissionLink" do
    discussion = Discussion.create!(:discussable => closed_project, :view_permission => 'create_discussions')

    equal discussion.permission_link.component_view_permission.to_s, 'create_discussions'
  end
end