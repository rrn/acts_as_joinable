class Discussion < ActiveRecord::Base
	belongs_to :discussable, :polymorphic => true, :optional => true
	
  acts_as_joinable_component :parent => 'discussable', :polymorphic => true
end