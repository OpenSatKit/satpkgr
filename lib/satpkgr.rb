require 'satpkgr/version.rb'

module SatPkgr

	class SatPkgr
			@@conf_file_name = 'satpkgr.json'
			@@pkg_dir_name = 'sat_modules'
			@@cosmos_launcher_config_location = File.join('config','tools','launcher','launcher.txt')

		def initialize(main_dir)

			@main_dir = main_dir
			@pkg_dir = File.join(main_dir,@@pkg_dir_name)
			@conf_file = File.join(main_dir,@@conf_file_name)

			unless File.exist?(@conf_file)
				raise "File does not exist: #{@conf_file}. Use `satpkgr init`."
			end

			@conf_hash = JSON.load (File.new(@conf_file))
		end

		def self.initPackage(main_dir)

			conf_file = File.join(main_dir,@@conf_file_name)

			pkg_conf = {
			  "name" => "username/package_name",
			  "description" => "what your package does",
			  "version" => "0.0.1",
			  "author" => "your name",
			  "cosmos" => {
			    "launcher" => "your_app_launcher.rb"
			  },
			  "cfs" => {
			  },
			  "dependencies" => {
			    "johannkm/OpenSatKit-example" => "0.0.1"
			  }
			}

			File.open(conf_file,"w") do |f|
			  f.write(JSON.pretty_generate(pkg_conf))
			end
		end

		def installAllPackages
			packages = @conf_hash['dependencies'].keys

			if packages.size == 0
				raise "No packages are listed in #{@conf_file}"
			else
				packages.each do |package|
					puts "Installing package '#{package}'"
					package_address_split = package.split('/')
	        unless package_address_split.size == 2
	          raise "Bad package address: '#{package}'"
	        end
	        installPackage(package_address_split[0], package_address_split[1])
	        puts "Success!"
				end
			end

		end

		def installPackage(username, repository)

			web_address = "https://github.com/#{username}/#{repository}/archive/master.zip"
			local_address = File.join(@pkg_dir, username)
			zipfile_name = File.join(local_address, "#{repository}.zip")

			begin
				open(web_address) do |uri|

					unless File.directory?(@pkg_dir)
						Dir.mkdir(@pkg_dir)
					end

					unless File.directory?("#{@pkg_dir}/#{username}")
						Dir.mkdir("#{@pkg_dir}/#{username}")
					end

					open(zipfile_name, 'wb') do |zipfile|
						zipfile.write(uri.read)
					end

					@conf_hash['dependencies']["#{username}/#{repository}"] = 'master'
					saveConf

				end
			rescue OpenURI::HTTPError => error
				response = error.io
				raise "#{response.status} on '#{web_address}'"
			end


			Zip::File.open(zipfile_name) do |zipfile|
				zipfile.each do |entry|

					entry_name = File.join(local_address, entry.name)

					unless File.exist?(entry_name)
						FileUtils::mkdir_p(File.dirname(entry_name))
						zipfile.extract(entry, entry_name)
					end
				end
			end

			extracted_name = "#{repository}-master"
			extracted_address = File.join(local_address, extracted_name)
			extracted_address_relative = File.join('..', @@pkg_dir_name, username, extracted_name) # cosmos launcher looks in tool directory

			installed_config = JSON.load (File.new( File.join(extracted_address, @@conf_file_name)))
			installed_config_cosmos_launcher = installed_config['cosmos']['launcher']
			cosmos_launcher_location = File.join(extracted_address_relative, 'cosmos', installed_config_cosmos_launcher)

			File.open(@@cosmos_launcher_config_location, 'a') do |file|
				file.write ("\nTOOL \"#{repository}\" \"LAUNCH #{cosmos_launcher_location}\"")
			end

		end

		def uninstallPackage(username, repository)



		end

		def saveConf
			File.open(@conf_file,"w") do |f|
			  f.write(JSON.pretty_generate(@conf_hash))
			end
		end

	end
end

require 'json'
require 'open-uri'
require 'zip'