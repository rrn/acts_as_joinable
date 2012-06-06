# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require File.expand_path("../dummy/config/environment.rb",  __FILE__)
require "rails/test_help"

Rails.backtrace_cleaner.remove_silencers!

# Run any available migrations
ActiveRecord::Migrator.migrate File.expand_path("../dummy/db/migrate/", __FILE__)

# Log queries to STDOUT
# ActiveRecord::Base.logger = Logger.new(STDOUT)

def equal(actual, expected)
  assert_equal expected, actual
end

def current_user
	@current_user ||= User.create!(:name => "Ryan")
end

def closed_project
	Project.create!(:default_permission_set_attributes => {:access_model => "closed"}, :user => current_user)
end

def with_view_permission(klass, permission, &block)
	old_view_permission = klass.view_permission
	
	klass.view_permission = permission
	yield
	klass.view_permission = old_view_permission
end