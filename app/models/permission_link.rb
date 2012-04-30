class PermissionLink < ActiveRecord::Base
  belongs_to :joinable, :polymorphic => true
  belongs_to :component, :polymorphic => true

  validates_uniqueness_of :component_id, :scope => [:joinable_type, :joinable_id, :component_type]
end