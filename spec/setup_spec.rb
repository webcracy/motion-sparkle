# frozen_string_literal: true

require File.expand_path('spec_utils', __dir__)

module Motion
  module Project
    class Config
      attr_writer :project_dir
    end
  end
end

describe 'Sparkle setup' do
  before(:all) do
    SpecUtils::TemporaryDirectory.teardown
    SpecUtils::TemporaryDirectory.setup

    FileUtils.mkdir_p("#{SpecUtils::TemporaryDirectory.directory}resources")
    FileUtils.mkdir_p("#{SpecUtils::TemporaryDirectory.directory}vendor")
    FileUtils.touch("#{SpecUtils::TemporaryDirectory.directory}.gitignore")
  end

  context 'something' do
    before do
      @config = App.config
      @config.project_dir = SpecUtils::TemporaryDirectory.directory.to_s
      @config.instance_eval do
        pods do
          pod 'Sparkle', POD_VERSION
        end

        sparkle do
          release :base_url, 'http://example.com/'
          # release :public_key, 'public_key.pem'
          publish :public_key, '<YOUR-EDDSA-PUBLIC-KEY>'
          release :version, '1.0'

          # Optional config options
          release :feed_base_url, 'http://rss.example.com/'
          release :feed_filename, 'example.xml'
          release :notes_base_url, 'http://www.example.com/'
          release :notes_filename, 'example.html'
          release :package_base_url, 'http://download.example.com/'
          release :package_filename, 'example.zip'
          # publish :use_exported_private_key, true
        end
      end

      Rake::Task['pod:install'].invoke
      Rake::Task['sparkle:setup'].invoke
      # Rake::Task['sparkle:setup_certificates'].invoke
    end

    it 'should create private certificate' do
      expect(File.exist?(@config.sparkle.private_key_path.to_s)).to be_truthy
    end

    it 'should create public certificate' do
      expect(File.exist?(@config.sparkle.public_key_path.to_s)).to be_truthy
    end

    it 'should add files to gitignore' do
      a = `cat .gitignore`
      expect(a.strip).not_to eq ''
    end
  end
end
