require File.dirname(__FILE__) + '/../spec_helper'

describe "A class that acts_as_permissable_proxy" do

  before :all do
    connect
    @owner_project = create_user(:owner => "owner")
  end
  
  before :each do
    @project = create_project(:name => "Project", :user_id => @owner_project.id )
    @first = create_user(:owner => "first")
    add_access_level(@project, @first, "discuss")
    Permission.any_instance.stubs(:destroy_related_memberships).returns(true)
  end

  context "The Discussion Proxy class" do
  end
  
  context "The Feed Proxy class" do
  end
  
  before :each do
    @first.destroy
  end
  
  after :all do
    @owner_project.destroy
  end
end

