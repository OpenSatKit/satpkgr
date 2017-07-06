require File.join([File.dirname(__FILE__), 'lib', 'satpkgr', 'version.rb'])
Gem::Specification.new do |s|
  s.name = 'satpkgr'
  s.version = Satpkgr::VERSION
  s.description = 'Install packages for OpenSatKit'
  s.author = 'Johann Miller'
  s.email = 'johann.k.miller@nasa.gov'
  s.homepage = 'http://johannmiller.com'
  s.platform = Gem::Platform::RUBY
  s.summary = 'Add packages to extend COSMOS and cFS functionality'
  s.files = `git ls-files`.split("\n")
  s.require_paths << 'lib'
  s.bindir = 'bin'
  s.executables << 'satpkgr'
  s.add_runtime_dependency('gli', '2.16.0')
  s.add_runtime_dependency('rubyzip', '1.2.1')

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'rubocop-rspec'
end
