require 'test_helper'

class ActsAsJoinableTest < ActiveSupport::TestCase
	test "should be able to return a list of records where a particular user has the given permission" do
		user = create_user
		project1 = create_project
		project2 = create_project
		project2.memberships.create!(:user => user, :permissions => :delete_discussions)

	 	assert_equal [project2], Project.with_permission(user, :delete_discussions)
	end	
end
