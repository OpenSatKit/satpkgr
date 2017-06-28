# Ensure we require the local version and not one we might have installed already
require File.join([File.dirname(__FILE__),'lib','satpkgr','version.rb'])
spec = Gem::Specification.new do |s| 
  s.name = 'satpkgr'
  s.version = Satpkgr::VERSION
  s.description = "Install packages for OpenSatKit"
  s.author = 'Johann Miller'
  s.email = 'johann.k.miller@nasa.gov'
  s.homepage = 'http://johannmiller.com'
  s.platform = Gem::Platform::RUBY
  s.summary = 'Add packages to extend COSMOS and cFS functionality'
  s.files = `git ls-files`.split("
")
  s.require_paths << 'lib'
  s.bindir = 'bin'
  s.executables << 'satpkgr'
  s.add_runtime_dependency('gli','2.16.0')
  s.add_runtime_dependency('rubyzip','1.2.1')

end
