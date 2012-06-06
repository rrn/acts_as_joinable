require 'test_helper'

class JoinableTest < ActiveSupport::TestCase
	test "Saving a joinable creates correct supporting models" do
    project = Project.create!(:default_permission_set_attributes => {:access_model => "closed"}, :user => current_user)
    
    equal project.memberships.count, 1
    equal project.memberships.first.user, current_user
    equal project.default_permission_set.permissions_string, 'find'
  end
end