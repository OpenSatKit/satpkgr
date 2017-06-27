require 'satpkgr/version.rb'

module SatPkgr

	class SatPkgr
		def initialize(main_dir)
			@main_dir = main_dir
			@pkg_dir = "#{main_dir}/sat_modules/"

			unless File.directory?(@pkg_dir)
				Dir.mkdir(@pkg_dir)
			end
		end

		def initPackage(options, args)

			pkg_conf = {
				'name' => 'package name',
				'description' => 'an openSatKit package',
				'version' => '0.0.1',
				'author' => 'your name',
				'dependencies' => {
					'johannkm/OpenSatKit-example' => '0.0.1'
				}
			}

			File.open("./satpkgr.json","w") do |f|
			  f.write(JSON.pretty_generate(pkg_conf))
			end
		end


		def installPackage(options, full)
			dir = full.split('/')[0]
			unless File.directory?("#{@pkg_dir}/#{dir}")
				Dir.mkdir("#{@pkg_dir}/#{dir}")
			end
			open("#{@pkg_dir + full}.zip", 'wb') do |file|
				open("https://github.com/#{full}/archive/master.zip") do |uri|
					file.write(uri.read)
				end
			end

			Zip::File.open("#{@pkg_dir + full}.zip") do |zipfile|
				zipfile.each do |entry|
					unless File.exist?(@pkg_dir + dir + "/" + entry.name)
						FileUtils::mkdir_p(@pkg_dir + dir + "/" + File.dirname(entry.name))
						zipfile.extract(entry, @pkg_dir + dir + "/" + entry.name)
					end
				end
			end
		end


	end
end

require 'json'
require 'open-uri'
require 'zip'