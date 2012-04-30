require 'pathname'
dir = Pathname(__FILE__).dirname
# Initialize acts_as_permissable models for usage
require dir.join('..', 'init')

# Add in all the models, to be used (other than acts_as_permissable models)
relative = dir.join('..', 'models')
Dir.entries(relative).each do
|entry|
  if File.extname(entry) == '.rb'
    require File.join(relative, entry)
  end
end

#Helper additions
require dir.join('helpers').join('fixjour_builders')
require dir.join('helpers').join('helper_methods')


module Spec::Example::ExampleGroupMethods
  alias :context :describe
end

Spec::Runner.configure do |config|
  config.mock_with :mocha
  config.include(Fixjour)
end

#ActiveRecord direct connection
def connect
  config = YAML::load(IO.read(File.dirname(__FILE__)+ "/.." + '/config/database.yml'))
  ActiveRecord::Base.establish_connection(config)
end