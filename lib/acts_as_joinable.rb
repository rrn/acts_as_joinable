require 'joinable/acts_as_permissable'
require 'joinable/acts_as_joinable'
require 'joinable/acts_as_joinable_component'
require 'joinable/acts_as_member'

require 'joinable/permissions_attribute_wrapper'

module ActsAsJoinable
  class Engine < Rails::Engine
    initializer "acts_as_joinable.init" do
      ActiveRecord::Base.send :extend, Joinable::ActsAsJoinable::ActMethod
      ActiveRecord::Base.send :extend, Joinable::ActsAsJoinableComponent::ActMethod
      ActiveRecord::Base.send :extend, Joinable::ActsAsMember::ActMethod
    end    
  end
end