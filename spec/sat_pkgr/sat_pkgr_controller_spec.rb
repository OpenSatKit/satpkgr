require 'spec_helper.rb'
require 'json'

describe SatPkgr::SatPkgrController do
  context 'given a directory with a config file' do
    it 'creates a new instance' do
      tmpdir do
        create_conf_file
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
          described_class.init_package('.')
          json_file = 'satpkgr.json'
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

  describe '#install_multiple_packages' do
    context 'given a config file with no dependencies' do
      it 'fails' do
        tmpdir do
          create_conf_file('{"dependencies": {}}')
          pkgr = described_class.new('.')

          expect do
            pkgr.install_multiple_packages([])
          end .to raise_error(RuntimeError, /No packages are listed/)
        end
      end
    end

    context 'given a config file with several dependencies' do
      it 'calls #install_package for each' do
        tmpdir do
          create_conf_file('{"dependencies":'\
            '{"user1/app1":"master","user2/app2":"master"}}')
          pkgr = described_class.new('.')
          allow(pkgr).to receive(:install_package)

          pkgr.install_multiple_packages([])
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
        org = 'OpenSatKit'
        repo = 'OpenSatKit-example'
        address = "#{org}/#{repo}"
        code_dir = File.join('sat_modules', org, "#{repo}-master")

        tmpdir do
          create_demo_dir(org, repo)
          pkgr = described_class.new('.')

          expect do
            pkgr.install_package(org, repo)
          end .not_to raise_error
          expect(Dir).to exist(code_dir)

          conf = JSON.parse(File.open('satpkgr.json', 'r').read)['dependencies']
          expect(conf).to have_key(address.to_s)
        end
      end
    end

    context "given a repository that doesn't exist" do
      it 'fails' do
        tmpdir do
          create_conf_file('{"dependencies": {}}')
          pkgr = described_class.new('.')

          expect do
            pkgr.install_package('null', 'null')
          end .to raise_error(RuntimeError, /404/)
        end
      end
    end

    context "given a repository that isn't a satpkgr application" do
      it 'fails' do
        tmpdir do
          create_conf_file('{"dependencies": {}}')
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
        org = 'example_user'
        repo = 'example_app'
        app_dir = File.join('sat_modules', org, "#{repo}-master")

        tmpdir do
          create_demo_dir(org, repo)
          install_dummy_app(org, repo)
          pkgr = described_class.new('.')

          expect do
            pkgr.uninstall_package(org, repo)
          end .not_to raise_error
          conf = JSON.parse(File.open('satpkgr.json', 'r').read)
          expect(Dir).not_to exist(app_dir)
          expect(conf['dependencies'])
            .not_to have_key("#{org}/#{repo}")
        end
      end
    end
  end

  describe '#uninstall_package' do
    context 'given a currently installed package' do
      it 'deletes the package' do
        org = 'example_user'
        repo = 'example_app'
        app_dir = File.join('sat_modules', org, "#{repo}-master")

        tmpdir do
          create_demo_dir(org, repo)
          install_dummy_app(org, repo)
          pkgr = described_class.new('.')

          expect do
            pkgr.uninstall_package(org, repo)
          end .not_to raise_error
          conf = JSON.parse(File.open('satpkgr.json', 'r').read)
          expect(Dir).not_to exist(app_dir)
          expect(conf['dependencies'])
            .not_to have_key("#{org}/#{repo}")
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
          create_conf_file
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
          create_conf_file
          pkgr = described_class.new('.')

          expect do
            pkgr.remove_package_directory
          end .to raise_error(/No such file or directory/)
        end
      end
    end
  end
end

def create_conf_file(contents = '')
  ret = nil
  File.open('satpkgr.json', 'w') do |file|
    file.write(contents)

    ret = file
  end
  ret
end

def create_demo_dir(org, repo)
  FileUtils.mkdir_p(File.join('config', 'tools', 'launcher'))
  launcher = File.join('config', 'tools', 'launcher', 'launcher.txt')
  launcher_line = "TOOL \"#{repo}\" \"LAUNCH "\
    "../sat_modules/#{org}/#{repo}-master/cosmos/launcher.rb\""
  File.open(launcher, 'w') do |file|
    file.write(launcher_line)
  end
  create_conf_file('{"dependencies": {}}')
end

def install_dummy_app(org, repo)
  FileUtils.mkdir_p(
    File.join('sat_modules', org, "#{repo}-master")
  )
  create_conf_file("{\"dependencies\": {\"#{org}/#{repo}\":\"master\"}}")
end
