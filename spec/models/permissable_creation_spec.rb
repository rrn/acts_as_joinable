# To change this template, choose Tools | Templates
# and open the template in the editor.
require File.dirname(__FILE__) + '/../spec_helper'

describe "Permissable objects after being instantiated" do
  before :all do
    connect
    @owner = create_user(:owner => "owner")
  end
  before :each do
    @project = new_project(:owner => @owner)
    Permission.any_instance.stubs(:destroy_related_memberships).returns(true)
  end

  it "adds an owner permission" do
    @project.save!
    owners_project_permissions= @project.permissions(@owner)
    owners_project_permissions.should have_at_most(1).Permission
  end

  it "Permissable Owner's have a 'own' permission" do
    @project.save!
    @project.permissions(@owner).should_not == nil
    @project.permissions(@owner).first.has_access?("own").should be_true
  end

  it "has only one Pemission to begin with" do
    @project.save!
    @project.permissions.length.should == 1
  end

  after :each do
    @project.destroy
  end
  after :all do
    @owner.destroy
  end
end

