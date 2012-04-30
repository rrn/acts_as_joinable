require File.dirname(__FILE__) + '/../spec_helper'

describe "Permissable proxies " do

  before :all do
    connect
    @owner = create_user(:sam)
  end

  before :each do
    #Make sure not to destroy related memberships, while still coupled in plugin
    Permission.any_instance.stubs(:destroy_related_memberships).returns(true)

    #instantiate project
    @project = create_project(:owner => @owner)
    #instantiate users, allow one user to discuss on the Project
    @tyler = create_user(:owner => :tyle)
    @joanna =create_user(:owner => :joanna)
    @marie = create_user(:owner => :marie)

    add_access_level(@project, @joanna, "discuss")

    #Instantiate discussion using User unassociated with Project, and @project as its acts_as_permissable parent
    @discussion = create_discussion(:owner => @marie, :discussible => @project)
    #Instantiate feed, with @discussion as it acts_as_permissable_proxy parent
    @feed =create_feed(:feedable => @discussion)
  end

  it "has access to its Parent(A Project)" do
    parent =  @discussion.permission_inheritance_target.first
    parent.should == @project
  end

  it "User can not view a Discussion even if they own the Discussion until permissions are elevated" do
    @discussion.viewable_by?(@marie).should_not == true
    add_access_level(@project, @marie, 'discuss')
    @discussion.viewable_by?(@marie).should == true
  end

  it "responds to being a Permissable Proxy" do
    @discussion.is_permissable_proxy.should == true
  end

  it "User can't view a Discussion if they cannot 'discuss' its Parent Project, and do not own the Project or the Discussion" do
    add_access_level(@project, @tyler, "view")
    @discussion.viewable_by?(@tyler).should == false
  end

  it "User can view a Discussion if they hold a 'discuss' permission upon its Parent, and are not the Owner of the Discussion or the Parent Project" do
    add_access_level(@project, @tyler, "discuss")
    @discussion.viewable_by?(@tyler).should == true
  end

  describe "has one Feed which" do
    it "is a Permissable Proxy instance" do
      @feed.is_permissable_proxy.should == true
    end

    it "has access to its Parent(A project) by way of permission_inheritance_target" do
      @feed.permission_inheritance_target.first.should == @project
    end

    it "has the same Parent(A Project) as it's Parent Proxy (A Discussion) by way of permission_inheritance_target" do
      @feed.permission_inheritance_target.should == @discussion.permission_inheritance_target
    end

    it "has to go through it's Permissable Proxy Parent to find its acts_as_permissable Parent" do
      @feed.expects(:next_link).at_least_once
      @feed.permission_inheritance_target
    end
  end

  after :each do
    [@feed, @discussion, @marie, @tyler, @joanna].each{|model| model.destroy}
  end

  after :all do
    @owner.destroy
  end
end
