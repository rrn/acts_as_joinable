require File.dirname(__FILE__) + '/../spec_helper'

describe "Flexing caching" do

  before :each do
    connect                          
    @owner_project = create_user(:owner => "owner")
    @private_project = create_project(:user_id => @owner_project.id)
    @oliver = create_user( :owner => "oliver")
    Permission.any_instance.stubs(:destroy_related_memberships).returns(true)
  end

  it "should calculate permissions (access level)ble_by? result after being called" do
    #Givens
    add_access_level(@private_project, @oliver, "view")
    to_return = "anything"
    #so that we can test that the method get called, but returning an SQL like object is too much effort
    Project.expects(:with_permission).with(@oliver, "view").returns(to_return)
    to_return.expects(:exists?).returns(true)
    #Thens
    @private_project.viewable_by?(@oliver)
  end

  it "should not calculate permissions with second call, to (access level)ble_by?" do
    #Helpers
    cache_path = "permissions/#{@private_project.class.table_name}/#{@private_project.id}/user_#{@oliver.id}"

    #Givens
    add_access_level(@private_project, @oliver, "view")
    to_return = "anything"
    to_return.stubs(:exists?).returns(true)
    #so that we can test that the method get called, but returning an SQL like object is too much effort
    Project.expects(:with_permission).with(@oliver, "view").returns(to_return).times(1)

    #Thens
    @private_project.viewable_by?(@oliver)
    #Make sure it reads, and then pass back what it normally would return
    Project.expects(:with_permission).with(@oliver, "view").never
    @private_project.viewable_by?(@oliver)
  end

  after :each do
    @owner_project.destroy
  end
end