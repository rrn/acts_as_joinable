# GEM DEPENDENCIES
require 'postgres_ext'

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

    config.to_prepare do
      if defined?(ActsAsFeedable::Engine)
        require 'joinable/feedable_extensions'
        FeedableExtensions.add
      else
        puts "[ActsAsJoinable] ActsAsFeedable not loaded. Skipping extensions."
      end
    end
  end
end