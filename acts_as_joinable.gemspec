Gem::Specification.new do |s|
  s.name = 'acts_as_joinable'
  s.version = '1.1.0'
  s.date = %q{2012-04-30}
  s.email = 'technical@rrnpilot.org'
  s.homepage = 'http://github.com/rrn/acts_as_joinable'
  s.summary = 'An easy to use permissions system'
  s.description = 'Adds access control to objects by giving them members, each with configurable permissions.'
  s.authors = ['Ryan Wallace', 'Nicholas Jakobsen']
  s.require_path = "lib"
  s.files = Dir.glob("{app,lib}/**/*") + %w(README.rdoc)
  s.add_dependency('postgres_ext', '~> 0.2.2')
end
