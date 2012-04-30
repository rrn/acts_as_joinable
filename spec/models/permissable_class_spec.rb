require File.dirname(__FILE__) + '/../spec_helper'

describe "A class that acts_as_permissable" do
  before :all do
    connect
  end

  before :each do
    Permission.any_instance.stubs(:destroy_related_memberships).returns(true)
    @owner = create_user(:owner => 'owner')
    @private_project= create_project(:owner=> @owner)
    @public_project= create_project(:owner => @owner)
  end

  describe "allows queries to be made about User's interactions with permissable models" do
    before :each do
      @tom = create_user(:owner => 'tom')
      add_access_level(@private_project, @tom, 'discuss')
      @toms_project = create_project(:owner => @tom)
    end

    it "find all accessible Projects to a User with a specific access_level" do
      projects_returned = Project.with_permission(@tom, 'discuss')
      #As tom owns one projects and holds a discuss permission for the other
      projects_returned.should have(2).things
    end

    it "finds all Public projects that allow access with atleast the access level in question" do
      add_access_level(@public_project, :public, 'administer')
      projects_returned = Project.with_collaborative_permission('administer')
      projects_returned.should have_at_most(1).Project
    end

    context "finds Project accessible to a User given a permission through a Public permission" do
      before :each do
        add_access_level(@public_project, :public, 'administer')
      end

      it "returns accessible Project correctly, when User does not have lower access levels than the Public permission" do
        projects_returned = Project.with_public_permission(@tom, 'administer')
        #Tom should be able to administer a project with a Public permission given to administer
        projects_returned.should have(1).Project
      end
      
      #TODO this method is not used
      it "does not return Projects that Tom holds a lower access level than the Public permissions access level" do
        add_access_level(@public_project, @tom, 'discuss')
        projects_returned = Project.with_public_permission(@tom, 'administer')
        #Tom should not be able to administer a project with a Public permission given to administer, when he has a specific discuss permission given to him
        projects_returned.should be_empty
      end
    end
  end

  describe "finds and returns a permissable instance"  do
    before :each do
      @associated_user = create_user(:owner=> "associated")
      add_access_level(@private_project, @associated_user, 'view')
      @unassociated_user = create_user(:owner=> "unassociated")
    end

    it "when supplied with a valid associated user and valid permissable id" do
      Project.find_with_privacy(@private_project, @associated_user).should == @private_project
    end

    it "when supplied with its owner and valid permissable id" do
      Project.find_with_privacy(@private_project, @owner).should == @private_project
    end

    context "when supplied with a permissable id with a Public access" do
      it "and a user associated with the permissable" do
        add_access_level(@public_project, @associated_user, 'view')
        Project.find_with_privacy(@public_project.id, @associated_user).should == @public_project
      end
      it "and the owner of the permissable" do
        Project.find_with_privacy(@public_project.id, @owner).should == @public_project
      end
    end

    context "unless" do
      it "an invalid id is supplied, and any user" do
        lambda{Project.find_with_privacy(Project.last.id + rand(100000), @associated_user)}.should raise_error(ActiveRecord::RecordNotFound)
      end
      it "an unassociated user is supplied" do
        lambda{Project.find_with_privacy(@private_project.id, @unassociated_user)}.should raise_error(ActiveRecord::RecordNotFound)
      end
    end
    after :each do
      [ @associated_user, @unassociated_user].each { |instance| instance.destroy }
    end
  end
  after :each do
    [@owner, @private_project, @public_project].each {|instance| instance.destroy}
  end
end
