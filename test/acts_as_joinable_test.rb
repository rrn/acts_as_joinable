require 'test_helper'

class ActsAsJoinableTest < ActiveSupport::TestCase
	test "should be able to return a list of records where a particular user has the given permission" do
		user = create_user
		project1 = create_project
		project2 = create_project
		project2.memberships.create!(:user => user, :permissions => :delete_discussions)

	 	assert_equal [project2], Project.with_permission(user, :delete_discussions)
	end

	test "when creating, should build a default permission set if one doesn't exist" do
		project = create_project(:default_permission_set => nil)

		assert project.default_permission_set
	end

	test "when creating, should not build a default permission set if one exists" do
		default_permission_set = DefaultPermissionSet.new
		project = create_project(:default_permission_set => default_permission_set)

		assert default_permission_set, project.default_permission_set
	end

	test "should be able to get a result could while limiting and scoping by permissions" do
		2.times { create_project }

		debug_active_record do
			Project.with_permission(current_user, :find).limit(10).count
		end

		assert_equal 2, Project.with_permission(current_user, :find).limit(10).count
	end
end
