# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require File.expand_path("../dummy/config/environment.rb",  __FILE__)
require "rails/test_help"

Rails.backtrace_cleaner.remove_silencers!

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

# Create the database
`dropdb acts_as_joinable_test`
`createdb acts_as_joinable_test`

# Run any available migrations
ActiveRecord::Migrator.migrate File.expand_path("../dummy/db/migrate/", __FILE__)

# Load fixtures from the engine
if ActiveSupport::TestCase.method_defined?(:fixture_path=)
  ActiveSupport::TestCase.fixture_path = File.expand_path("../fixtures", __FILE__)
end

def equal(actual, expected)
  assert_equal expected, actual
end

def current_user
	@current_user ||= create_user
end

def create_user(attributes = {})
	User.create!(attributes.reverse_merge :name => "User #{User.maximum(:id).to_i + 1}")
end

def create_project(attributes = {})
	Project.create!(attributes.reverse_merge :user => current_user)
end

def create_closed_project(attributes = {})
	create_project(attributes.reverse_merge :default_permission_set_attributes => {:access_model => "closed"})
end

def with_view_permission(klass, permission, &block)
	old_view_permission = klass.view_permission
	
	klass.view_permission = permission
	yield
	klass.view_permission = old_view_permission
end
