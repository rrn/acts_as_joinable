class InitialTables < ActiveRecord::Migration[4.2]
  def change
	  create_table :memberships, :force => true do |t|
	    t.belongs_to :joinable, :polymorphic => true
	    t.belongs_to :user
	    t.string :permissions, :array => true
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
	    t.string :permissions, :array => true
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
	    t.string :permissions, :array => true
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

	  create_table :feeds, :force => true do |t|
	  	t.belongs_to :feedable, :polymorphic => true
	  end
  end
end
