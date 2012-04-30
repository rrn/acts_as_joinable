require File.dirname(__FILE__) + '/../spec_helper'

describe "Proxies able_by? method" do
  before :all do
    connect
    @sam = create_user(:owner => :sam)
    @project = create_project(:owner => @sam)
  end
  
  before :each do
    Permission.any_instance.stubs(:destroy_related_memberships).returns(true)
    
    @sara = create_user(:owner => :marie)
    add_access_level(@project, @sara, "discuss")
    @discussion = create_discussion(:owner => @sara, :discussible => @project)
    @tony = create_user(:owner => :tony)
  end

  it "should be viewable by its owner" do
    @discussion.viewable_by?(@sara).should be_true
  end

  it "should be viewable by its discussible's owner" do
    @discussion.viewable_by?(@sam).should be_true
  end

  it "should not be viewable by just anyone" do
    @discussion.viewable_by?(@tony).should be_false
  end

  after :each do
    [@sara, @discussion, @tony].each do |instance|
      instance.destroy
    end
  end

  after :all do
    [@sam, @project].each do |instance|
      instance.destroy
    end
  end
end