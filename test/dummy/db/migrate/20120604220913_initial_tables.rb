class InitialTables < ActiveRecord::Migration
  def change
	  create_table :memberships, :force => true do |t|
	    t.belongs_to :joinable, :polymorphic => true
	    t.belongs_to :user
	    t.text :permissions
	    t.timestamps
	  end

	  create_table :membership_requests, :force => true do |t|
	    t.belongs_to :joinable, :polymorphic => true
	    t.belongs_to :user
	    t.text :message
	    t.timestamps
	  end

	  create_table :membership_invitations, :force => true do |t|
	    t.belongs_to :joinable, :polymorphic => true
	    t.belongs_to :user
	    t.belongs_to :initiator
	    t.text :permissions
	    t.text :message
	    t.timestamps
	  end

	  create_table :permission_links, :force => true do |t|
	    t.belongs_to :joinable, :polymorphic => true
	    t.belongs_to :component, :polymorphic => true
	    t.string :component_view_permission
	  end

	  create_table :default_permission_sets, :force => true do |t|
	    t.belongs_to :joinable, :polymorphic => true
	    t.text :permissions
	    t.timestamps
	  end

	  create_table :projects, :force => true do |t|
	  	t.belongs_to :user
	  end

	  create_table :discussions, :force => true do |t|
	    t.belongs_to :discussable, :polymorphic => true
	  end

	  create_table :users, :force => true do |t|
	    t.string :name
	  end
  end
end
