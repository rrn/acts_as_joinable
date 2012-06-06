class Project < ActiveRecord::Base
	belongs_to :user
	
  acts_as_joinable :component_permissions => [{:discussions => [:view, :create, :delete]}]
end