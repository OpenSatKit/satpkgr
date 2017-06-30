require 'bundler/setup'
Bundler.setup

require 'satpkgr'

module Helpers

	def tmpdir
		Dir.mktmpdir do |dir|
			Dir.chdir dir do
				yield(dir)
			end
		end
	end
	
end


RSpec.configure do |c|
  c.include Helpers
end