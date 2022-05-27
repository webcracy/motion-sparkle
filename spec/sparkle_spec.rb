# frozen_string_literal: true

require File.expand_path('spec_utils', __dir__)

module Motion
  module Project
    class Config
      attr_writer :project_dir
    end
  end
end

# rubocop:disable Metrics/BlockLength
describe 'motion-sparkle-sandbox' do
  before(:all) do
    SpecUtils::TemporaryDirectory.teardown
    SpecUtils::TemporaryDirectory.setup

    FileUtils.mkdir_p("#{SpecUtils::TemporaryDirectory.directory}resources")
    FileUtils.mkdir_p("#{SpecUtils::TemporaryDirectory.directory}vendor")
    FileUtils.touch("#{SpecUtils::TemporaryDirectory.directory}.gitignore")
  end

  context 'configuration' do
    before do
      @config = App.config
      @config.sparkle = nil
      @config.project_dir = SpecUtils::TemporaryDirectory.directory.to_s
      @config.instance_eval do
        sparkle do
          release :base_url, 'http://example.com/'
        end
      end
    end

    describe 'base url' do
      it 'base url should be set correctly' do
        expect(@config.sparkle.appcast.base_url).to eq 'http://example.com/'
      end
    end

    describe 'feed url' do
      it 'uses default value' do
        expect(@config.info_plist['SUFeedURL']).to eq 'http://example.com/releases.xml'
      end

      it 'uses feed_base_url' do
        @config.sparkle.publish(:feed_base_url, 'http://rss.example.com/')

        expect(@config.info_plist['SUFeedURL']).to eq 'http://rss.example.com/releases.xml'
      end

      it 'uses feed_filename' do
        @config.sparkle.publish(:feed_base_url, 'http://rss.example.com/')
        @config.sparkle.publish(:feed_filename, 'example.xml')

        expect(@config.info_plist['SUFeedURL']).to eq 'http://rss.example.com/example.xml'
      end
    end

    describe 'appcast package base url' do
      it 'uses default value' do
        expect(@config.sparkle.appcast.package_base_url).to eq 'http://example.com/'
      end

      it 'uses package_base_url' do
        @config.sparkle.publish(:package_base_url, 'http://download.example.com/')

        expect(@config.sparkle.appcast.package_base_url).to eq 'http://download.example.com/'
      end
    end

    describe 'appcast package filename' do
      it 'has no default value' do
        expect(@config.sparkle.appcast.package_filename).to be_nil
      end

      it 'uses package_filename' do
        @config.sparkle.publish(:package_filename, 'example.zip')

        expect(@config.sparkle.appcast.package_filename).to eq 'example.zip'
      end
    end

    describe 'appcast releases notes base url' do
      it 'uses default value' do
        expect(@config.sparkle.appcast.notes_base_url).to eq 'http://example.com/'
      end

      it 'uses notes_base_url' do
        @config.sparkle.publish(:notes_base_url, 'http://download.example.com/')

        expect(@config.sparkle.appcast.notes_base_url).to eq 'http://download.example.com/'
      end
    end

    describe 'appcast release notes filename' do
      it 'has no default value' do
        expect(@config.sparkle.appcast.notes_filename).to be_nil
      end

      it 'uses package_filename' do
        @config.sparkle.publish(:notes_filename, 'release_notes.html')

        expect(@config.sparkle.appcast.notes_filename).to eq 'release_notes.html'
      end
    end

    it 'version and short version should be set correctly' do
      @config.sparkle.publish(:version, '1.0')

      expect(@config.version).to eq '1.0'
      expect(@config.short_version).to eq '1.0'
    end
  end

  context 'cocoapod' do
    before do
      @config = App.config
      @config.project_dir = SpecUtils::TemporaryDirectory.directory.to_s
      @config.instance_eval do
        pods do
          pod 'Sparkle', POD_VERSION
        end
      end

      Rake::Task['pod:install'].invoke
    end

    it 'Sparkle framework pod should be embedded' do
      sparkle_framework_path = 'vendor/Pods/Sparkle/Sparkle.framework'
      @config.pods.pods_libraries

      expect(@config.embedded_frameworks.first.end_with?(sparkle_framework_path)).to be_truthy
    end
  end
end
# rubocop:enable Metrics/BlockLength
