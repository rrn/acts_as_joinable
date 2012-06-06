# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require File.expand_path("../dummy/config/environment.rb",  __FILE__)
require "rails/test_help"

Rails.backtrace_cleaner.remove_silencers!

# Run any available migrations
ActiveRecord::Migrator.migrate File.expand_path("../dummy/db/migrate/", __FILE__)

ActiveRecord::Base.logger = Logger.new(STDOUT)

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

def equal(actual, expected)
  assert_equal expected, actual
end

def current_user
	@current_user ||= User.create!(:name => "Ryan")
end