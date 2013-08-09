class Discussion < ActiveRecord::Base
	belongs_to :discussable, :polymorphic => true
	
  acts_as_joinable_component :parent => 'discussable', :polymorphic => true
end