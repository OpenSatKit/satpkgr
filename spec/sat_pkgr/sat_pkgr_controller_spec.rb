require 'spec_helper.rb'
require 'json'

describe SatPkgr::SatPkgrController do
  context 'given a directory with a config file' do
    it 'creates a new instance' do
      tmpdir do
        File.open('satpkgr.json', 'w')
        expect { described_class.new('.') }.not_to raise_error
      end
    end
  end

  context 'given a directory without a config file' do
    it 'fails' do
      tmpdir do
        expect do
          described_class.new('.')
        end .to raise_error(RuntimeError, /File does not exist/)
      end
    end
  end

  describe '.init_package' do
    context 'given a directory' do
      it 'writes a json config file in the directory' do
        tmpdir do
          Dir.mkdir('temp')
          described_class.init_package('temp')
          json_file = File.join('temp', 'satpkgr.json')
          conf = nil

          expect(File).to exist(json_file)
          expect do
            conf = JSON.parse(File.open(json_file, 'r').read)
          end .not_to raise_error
          expect(conf.key?('name'))
        end
      end
    end
  end

  describe '#install_all_packages' do
    context 'given a config file with no dependencies' do
      it 'fails' do
        tmpdir do
          File.open('satpkgr.json', 'w') do |file|
            file.write('{"dependencies": {}}')
          end
          pkgr = described_class.new('.')

          expect do
            pkgr.install_all_packages
          end .to raise_error(RuntimeError, /No packages are listed/)
        end
      end
    end

    context 'given a config file with several dependencies' do
      it 'calls #install_package for each' do
        tmpdir do
          conf = '{"dependencies":'\
          '{"user1/app1":"master","user2/app2":"master"}}'
          File.open('satpkgr.json', 'w') do |file|
            file.write(conf)
          end
          pkgr = described_class.new('.')
          allow(pkgr).to receive(:install_package)

          pkgr.install_all_packages
          expect(pkgr).to have_received(:install_package)
            .with('user1', 'app1').once
          expect(pkgr).to have_received(:install_package)
            .with('user2', 'app2').once
        end
      end
    end
  end

  describe '#install_package' do
    context 'given a valid repository and cosmos config' do
      it 'downloads the application' do
        tmpdir do
          org = 'OpenSatKit'
          repo = 'OpenSatKit-example'
          address = "#{org}/#{repo}"
          FileUtils.mkdir_p(File.join('config', 'tools', 'launcher'))
          launcher = File.join('config', 'tools', 'launcher', 'launcher.txt')
          code_dir = File.join('sat_modules', org, "#{repo}-master")
          File.open(launcher, 'w')
          File.open('satpkgr.json', 'w') do |file|
            file.write('{"dependencies": {}}')
          end
          pkgr = described_class.new('.')

          expect do
            pkgr.install_package(org, repo)
          end .not_to raise_error
          expect(Dir).to exist(code_dir)
          expect(JSON.parse(File.open('satpkgr.json', 'r').read)['dependencies'])
            .to have_key(address.to_s)
        end
      end
    end

    context "given a repository that doesn't exist" do
      it 'fails' do
        tmpdir do
          File.open('satpkgr.json', 'w') do |file|
            file.write('{"dependencies": {}}')
          end
          pkgr = described_class.new('.')

          expect { pkgr.install_package('null', 'null') }.to raise_error(RuntimeError, /404/)
        end
      end
    end

    context "given a repository that isn't a satpkgr application" do
      it 'fails' do
        tmpdir do
          File.open('satpkgr.json', 'w') do |file|
            file.write('{"dependencies": {}}')
          end
          pkgr = described_class.new('.')

          expect do
            pkgr.install_package('OpenSatKit', 'satpkgr')
          end .to raise_error(/No such file or directory/)
        end
      end
    end
  end

  describe '#uninstall_package' do
    context 'given a currently installed package' do
      it 'deletes the package' do
        tmpdir do
          conf_file = File.join('config', 'tools', 'launcher', 'launcher.txt')
          FileUtils.mkdir_p(
            File.join('sat_modules', 'example_user', 'example_app-master')
          )
          File.open('satpkgr.json', 'w') do |file|
            file.write('{"dependencies": {"example_user/example_app":"master"}}')
          end
          pkgr = described_class.new('.')
          FileUtils.mkdir_p(File.join('config', 'tools', 'launcher'))
          File.open(conf_file, 'w') do |file|
            file.write('TOOL "example_app" "LAUNCH ../sat_modules/example_user/example_app-master/cosmos/launcher.rb')
          end

          expect { pkgr.uninstall_package('example_user', 'example_app') }.not_to raise_error
          expect(Dir).not_to exist(File.join('sat_modules', 'example_user', 'example_app-master'))
          expect(File.read(conf_file)).not_to include('example_app')
          expect(JSON.parse(File.open('satpkgr.json', 'r').read)['dependencies']).not_to have_key('example_user/example_app')
        end
      end
    end
  end

  describe '#remove_package_directory' do
    context 'given a directory that containes sat_modules' do
      it 'deletes sat_modules' do
        tmpdir do
          Dir.mkdir('sat_modules')
          File.open(File.join('sat_modules', 'temp.txt'), 'w')
          File.open('satpkgr.json', 'w')
          pkgr = described_class.new('.')

          expect(Dir).to exist('sat_modules')
          pkgr.remove_package_directory
          expect(Dir).not_to exist('sat_modules')
        end
      end
    end

    context 'given a directory that does not containes sat_modules' do
      it 'fails' do
        tmpdir do
          File.open('satpkgr.json', 'w')
          pkgr = described_class.new('.')

          expect { pkgr.remove_package_directory }.to raise_error(/No such file or directory/)
        end
      end
    end
  end
end
