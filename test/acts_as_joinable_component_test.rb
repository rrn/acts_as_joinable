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

  test "joinable method should recurse up the chain of joinable_components until it reaches and returns a joinable" do
    project = create_project
    discussion = Discussion.create!(:discussable => project)
    feed = Feed.create(:feedable => discussion)
    
    assert_equal project, feed.joinable
  end

  test "should be able to return a list of records where a particular user has a view permission" do
    project1 = create_project
    project2 = create_project    
    discussion1 = Discussion.create!(:discussable => project1)
    discussion2 = Discussion.create!(:discussable => project2)
    user = create_user
    project1.memberships.create!(:user => user, :permissions => :view_discussions)

    assert_equal [discussion1], Discussion.with_permission(user, :view_discussions)
  end

  test "should be able to return a list of records where a particular user has the given permission" do
    project1 = create_project
    project2 = create_project    
    discussion1 = Discussion.create!(:discussable => project1)
    discussion2 = Discussion.create!(:discussable => project2)
    user = create_user
    project1.memberships.create!(:user => user, :permissions => :delete_discussions)

    assert_equal [discussion1], Discussion.with_permission(user, :delete_discussions)
  end

  test "should be able to return a list of records where a particular user has the given 'join_and...' permission" do
    project1 = create_project
    project2 = create_project
    discussion1 = Discussion.create!(:discussable => project1)
    discussion2 = Discussion.create!(:discussable => project2)
    user = create_user
    project1.update_attribute(:default_permissions, :delete_discussions)

    assert_equal [discussion1], Discussion.with_permission(user, :join_and_delete_discussions)
  end  


  test "should be able to list the users who will be able to view the component once it is saved" do
    with_view_permission(Discussion, :view_discussions) do
      project = create_closed_project
      user1 = create_user
      user2 = create_user
      project.memberships.create!(:user => user1, :permissions => :view_discussions)
      discussion = Discussion.new(:discussable => project)

      assert discussion.who_will_be_able_to_view?.include?(user1)
      assert_not discussion.who_will_be_able_to_view?.include?(user2)
    end
  end

  # Test for https://github.com/rails/rails/issues/11824
  test "should be able to get a result could while limiting and scoping by permissions" do
    Discussion.create(:discussable => create_closed_project(:user => create_user))
    Discussion.create(:discussable => create_project)

    assert_equal 1, Discussion.with_permission(current_user, :view).limit(10).count
  end

  test "should be able to get a list of users with a given permission on a permissable" do
    user1 = create_user
    user2 = create_user

    project = create_project
    project.memberships.create!(:user => user1, :permissions => '')
    project.memberships.create!(:user => user2, :permissions => :delete_discussions)
    dsicussion = Discussion.create!(:discussable => project)
 
    assert_not dsicussion.who_can?(:delete_discussions).include?(user1)
    assert dsicussion.who_can?(:delete_discussions).include?(user2)    
  end

end