require File.dirname(__FILE__) + '/../spec_helper'

describe "An acts_as_permissable instance" do

  before :all do
    connect
  end

  before :each do
    #users
    @private_owner = create_user( :owner => "owner")
    @public_owner = create_user( :owner => "owner2")
    @oliver = create_user( "oliver")
    #projects
    @private_project = create_project(:owner => @private_owner)
    #Add oliver as a user to private project, now the project has 2 members => the owner, and oliver
    add_access_level(@private_project, @oliver, "view")
    @public_project = create_project(:owner => @public_owner)
    add_access_level(@public_project, :public, "view")

    Permission.any_instance.stubs(:destroy_related_memberships).returns(true)
  end

  before :each do

  end

  it "has a single Owner" do
    owners =   @private_project.who_can?(:own)
    owners.should have_at_most(1).User
    owners.first.should equal?(@private_owner)
  end

  it "can retrieve a list of all Users that hold a specific access level" do
    viewers = @private_project.who_can?(:view)
    viewers.should have 2.User
    [@private_owner, @oliver].each do
    |user|
      viewers.should include(user)
    end
  end

    it "does not have any permissions for this individual" do
      @private_project.permission_for(@oliver).should == (nil)
    end

    it "gets a permission added when an appropriate access level is added" do
      access_level_to_add = Project.access_levels.first.to_s

      add_access_level(@private_project, @oliver, access_level_to_add).should
      change(Permission.count).by_at_most(1)
    end

    it "does not allow own permission to be added to a permission for a non-owner, with no relation to this permissable" do
      add_access_level(@private_project, @oliver, 'own')
      Permission.find_by_actor_id(@oliver.id).should == nil
    end

    it "does not allow 'own' permission to be added to non-owning user, with prior permission to this permissable" do
      access_levels_to_add = ["administer", "own"]
      add_permission(@private_project, @oliver, access_levels_to_add)
      Permission.find_by_actor_id(@oliver.id).read_attribute(:access).include?('own').should_not == true
    end

  it "invalid access levels can't be added to Users' permissions" do
    lambda { add_access_level(@private_project, @oliver, "murder") }.should raise_error
  end

  context "with a PublicPermission with an access level of 'view" do
    it "is a publicly \"viewable\" Project" do
      @public_project.has_public_permission?(:view).should == true
    end

    it "gives permission for a random User to :view it" do
      rob = create_user(:owner =>  'Robert')
      @public_project.viewable_by?(rob).should == true
      rob.destroy
    end

    it "has access to full list of Users that do not have a specific access level" do
      @public_project.who_cannot?('own').should == (User.all - @public_owner)
    end
    it "reponds to having a public permission of 'view'" do
      @public_project.has_public_permission?(:view).should equal(true)
    end
    it "returns a list of all Users who can 'annotate' this project" do
      @public_project.who_can?('annotate').should == User.all
    end
  end

  context "with a PublicPermission of 'annotate' and a certain User holds a 'view' access level for this instance." do
    before :each do
      add_access_level(@public_project, :public, 'annotate')
      add_access_level(@public_project, @oliver, 'view')
    end
    it "returns a list of those user's who cannot 'annotate'" do
      @public_project.who_cannot('annotate').should have(1).User
      @public_project.who_cannot('annotate').first.should equal(@oliver)
    end
  end



  describe "when access levels for an acts_as_permissable are granted to a User" do
    #access attribute of a row permission, of a new user
    #(Only works if a working on a Permissable Object, otherwise no row entry will be evaluated yet)
    def oliver_access
      permission = @private_project.permission_for(@oliver)
    end

    before :each do
      add_access_level(@private_project, @oliver, 'discuss')
    end

    it "should be unaffected when existing access levels are being added to it" do
      lambda{add_access_level(@private_project, @oliver, 'view')}
    end

    it "should include the new access levels when valid access levels are added" do
      add_access_level(@private_project, @oliver, 'annotate')
      @private_project.should be_annotateable_by(@oliver)
    end

    it "changes after adding inherent dependency of the original access level using set_permissions" do
      pending("This method needs to be implemented")
    end
  end

  after :each do
    @oliver.destroy
    @private_owner.destroy
    @public_owner.destroy
    @private_project.destroy
    @public_project.destroy
  end
end
