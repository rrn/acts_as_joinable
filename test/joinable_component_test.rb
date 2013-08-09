require 'test_helper'

class JoinableComponentTest < ActiveSupport::TestCase
  test "joinable_component with joinable parent generates PermissionLink" do    
    discussion = Discussion.create!(:discussable => create_closed_project)

    equal discussion.permission_link.component_view_permission.to_s, 'view'
  end

  test "joinable_component with non-permissable parent generates no PermissionLink" do
  	discussion = Discussion.create!

    equal discussion.permission_link, nil
  end

  test "joinable_component with custom view_permission generates the correct PermissionLink" do
    with_view_permission(Discussion, :view_discussions) do
    	discussion = Discussion.create!(:discussable => create_closed_project)

    	equal discussion.permission_link.component_view_permission.to_s, 'view_discussions'
    end
  end

  test "joinable_component with custom lambda view_permission generates the correct PermissionLink" do
  	with_view_permission(Discussion, lambda {|discussion| :view if discussion.discussable.is_a?(Project)}) do
    	discussion = Discussion.create!(:discussable => create_closed_project)

    	equal discussion.permission_link.component_view_permission.to_s, 'view'
  	end
  end

  test "joinable_component with custom instance level view_permission generates the correct PermissionLink" do
    discussion = Discussion.create!(:discussable => create_closed_project, :view_permission => 'create_discussions')

    equal discussion.permission_link.component_view_permission.to_s, 'create_discussions'
  end

  test "should be able to list the users who will be able to view the component once it is saved" do
    with_view_permission(Discussion, :view_discussions) do
      project = create_closed_project
      p user1 = create_user
      p user2 = create_user
      project.memberships.create!(:user => user1, :permissions => :view_discussions)
      p project
      p project.membership_for(project.user)
      p project.membership_for(user1)


      discussion = Discussion.new(:discussable => create_closed_project)
      logger = ActiveRecord::Base.logger
      p discussion.view_permission
      ActiveRecord::Base.logger = Logger.new(STDOUT)
      p discussion.who_will_be_able_to_view?
      ActiveRecord::Base.logger = logger
      assert discussion.who_will_be_able_to_view?.include?(user1)
      assert_not discussion.who_will_be_able_to_view?.include?(user2)
    end
  end
end