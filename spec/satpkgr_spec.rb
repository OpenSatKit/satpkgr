require 'spec_helper.rb'
require 'json'

describe SatPkgr do
	describe SatPkgr do

		context "given a directory with a config file" do
			it "creates a new instance" do
				tmpdir do 	
					File.open('satpkgr.json','w')
					expect{SatPkgr::SatPkgr.new('.')}.to_not raise_error
				end
			end
		end

		context "given a directory without a config file" do
			it "fails" do
				tmpdir do
					expect{SatPkgr::SatPkgr.new('.')}.to raise_error(RuntimeError, /File does not exist/)
				end
			end
		end

		describe ".initPackage" do

			context "given a directory" do
				it "writes a json config file in the directory" do
					tmpdir do
						Dir.mkdir('temp')
						SatPkgr::SatPkgr.initPackage('temp')
						json_file = File.join('temp','satpkgr.json')
						conf = nil

						expect(File).to exist(json_file)
						expect{conf = JSON.load (File.new(json_file))}.to_not raise_error
						expect(conf.has_key? 'name')
					end
				end
			end

		end

		describe "#installAllPackages" do

			context "given a config file with no dependencies" do
				it "fails" do
					tmpdir do
						File.open('satpkgr.json','w') do |file|
							file.write('{"dependencies": {}}')
						end
						pkgr = SatPkgr::SatPkgr.new('.')

						expect{pkgr.installAllPackages}.to raise_error(RuntimeError, /No packages are listed/)
					end
				end
			end

			context "given a config file with several dependencies" do
				it "calls #installPackage for each" do
					tmpdir do
						File.open('satpkgr.json','w') do |file|
							file.write('{"dependencies": {"user1/app1":"master","user2/app2":"master"}}')
						end
						pkgr = SatPkgr::SatPkgr.new('.')

						expect(pkgr).to receive(:installPackage).with("user1","app1").once
						expect(pkgr).to receive(:installPackage).with("user2","app2").once
						pkgr.installAllPackages
					end
				end
			end

		end

		describe "#installPackage" do

			context "given a valid repository and cosmos config" do
				it "downloads the application" do
					tmpdir do
						FileUtils.mkdir_p(File.join('config','tools','launcher'))
						File.open(File.join('config','tools','launcher','launcher.txt'),'w')
						File.open('satpkgr.json','w') do |file|
							file.write('{"dependencies": {}}')
						end
						pkgr = SatPkgr::SatPkgr.new('.')

						expect{pkgr.installPackage('OpenSatKit','OpenSatKit-example')}.to_not raise_error
						expect(Dir).to exist(File.join('sat_modules','OpenSatKit', 'OpenSatKit-example-master'))
						expect(JSON.load(File.new('satpkgr.json'))['dependencies']).to have_key('OpenSatKit/OpenSatKit-example')
					end
				end
			end

			context "given a repository that doesn't exist" do
				it "fails" do
					tmpdir do
						File.open('satpkgr.json','w') do |file|
							file.write('{"dependencies": {}}')
						end
						pkgr = SatPkgr::SatPkgr.new('.')

						expect{pkgr.installPackage('null','null')}.to raise_error(RuntimeError, /404/)
					end
				end
			end

			context "given a repository that isn't a satpkgr application" do
				it "fails" do
					tmpdir do
						File.open('satpkgr.json','w') do |file|
							file.write('{"dependencies": {}}')
						end
						pkgr = SatPkgr::SatPkgr.new('.')

						expect{pkgr.installPackage('OpenSatKit','satpkgr')}.to raise_error(/No such file or directory/)
					end
				end
			end

		end

		describe "#uninstallPackage" do

			context "given a currently installed package" do
				it "deletes the package" do
					tmpdir do
						conf_file = File.join('config','tools','launcher','launcher.txt')
						FileUtils.mkdir_p(File.join('sat_modules','example_user','example_app-master'))
						File.open('satpkgr.json','w') do |file|
							file.write('{"dependencies": {"example_user/example_app":"master"}}')
						end
						pkgr = SatPkgr::SatPkgr.new('.')
						FileUtils.mkdir_p(File.join('config','tools','launcher'))
						File.open(conf_file,'w') do |file|
							file.write('TOOL "example_app" "LAUNCH ../sat_modules/example_user/example_app-master/cosmos/launcher.rb')
						end

						expect{pkgr.uninstallPackage('example_user','example_app')}.to_not raise_error
						expect(Dir).to_not exist(File.join('sat_modules','example_user','example_app-master'))
						expect(File.read(conf_file)).to_not include('example_app')
						expect(JSON.load(File.new('satpkgr.json'))['dependencies']).to_not have_key('example_user/example_app')
					end
				end
			end

		end

		describe "#removePackageDirectory" do

			context "given a directory that containes sat_modules" do
				it "deletes sat_modules" do
					tmpdir do
						Dir.mkdir('sat_modules')
						File.open(File.join('sat_modules','temp.txt'),'w')
						File.open('satpkgr.json','w')
						pkgr = SatPkgr::SatPkgr.new('.')

						expect(Dir).to exist('sat_modules')
						pkgr.removePackageDirectory
						expect(Dir).to_not exist('sat_modules')
					end
				end
			end

			context "given a directory that does not containes sat_modules" do
				it "fails" do
					tmpdir do
						File.open('satpkgr.json','w')
						pkgr = SatPkgr::SatPkgr.new('.')

						expect{pkgr.removePackageDirectory}.to raise_error(/No such file or directory/)
					end
				end
			end

		end


	end
end