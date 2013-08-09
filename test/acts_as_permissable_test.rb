require 'test_helper'

class ActsAsPermissableTest < ActiveSupport::TestCase
	test "should be able to get a list of users with a given permission on a permissable" do
		user1 = create_user
		user2 = create_user

		project = create_project
		project.memberships.create!(:user => user1, :permissions => '')
		project.memberships.create!(:user => user2, :permissions => :delete_discussions)
 
	 	assert_not project.who_can?(:delete_discussions).include?(user1)
		assert project.who_can?(:delete_discussions).include?(user2)		
	end

	test "should be able to return a list of records where a particular user has the given permission" do
		user = create_user
		project1 = create_project
		project2 = create_project
		project2.memberships.create!(:user => user, :permissions => :delete_discussions)

	 	assert_equal [project2], Project.with_permission(user, :delete_discussions)
	end
end
