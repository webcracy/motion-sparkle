# frozen_string_literal: true

require File.expand_path('spec_helper', __dir__)

module Motion
  module Project
    class Config
      attr_writer :project_dir
    end
  end; end

# rubocop:disable Metrics/BlockLength
describe 'motion-sparkle-sandbox' do
  extend SpecHelper::TemporaryDirectory

  before do
    unless @completed_setup
      teardown_temporary_directory
      setup_temporary_directory

      FileUtils.mkdir_p(temporary_directory + 'resources')
      FileUtils.mkdir_p(temporary_directory + 'vendor')
      FileUtils.touch(temporary_directory + '.gitignore')

      @config = App.config
      @config.project_dir = temporary_directory.to_s
      @config.instance_eval do
        pods do
          pod 'Sparkle', POD_VERSION
        end

        sparkle do
          release :base_url, 'http://example.com'
          release :public_key, 'public_key.pem'
          release :version, '1.0'
          # Optional config options
          release :feed_base_url, 'http://rss.example.com'
          release :feed_filename, 'example.xml'
          release :notes_base_url, 'http://www.example.com'
          release :notes_filename, 'example.html'
          release :package_base_url, 'http://download.example.com'
          release :package_filename, 'example.zip'
        end
      end

      Rake::Task['pod:install'].invoke
      Rake::Task['sparkle:setup'].invoke
      Rake::Task['sparkle:setup_certificates'].invoke

      @completed_setup = true
    end
  end

  it "Sparkle's release base url should be set correctly" do
    @config.sparkle.appcast.base_url.should.equal 'http://example.com'
  end

  it "Sparkle's feed url should be set correctly" do
    @config.info_plist['SUFeedURL'].should.equal 'http://rss.example.com/example.xml'
  end

  it "Sparkle's release notes url should be set correctly" do
    @config.sparkle.appcast.notes_url.should.equal 'http://www.example.com/example.html'
  end

  it "Sparkle's appcast package url should be set correctly" do
    @config.sparkle.appcast.package_url.should.equal 'http://download.example.com/example.zip'
  end

  it "Sparkle's public key should have custom name" do
    @config.info_plist['SUPublicDSAKeyFile'].should.equal 'public_key.pem'
  end

  it 'Version and short version should be set correctly' do
    @config.version.should.equal '1.0'
    @config.short_version.should.equal '1.0'
  end

  it 'Version should be same for short_version and version' do
    @config.version.should.equal @config.short_version
  end

  it 'Sparkle framework pod should be embedded' do
    sparkle_framework_path = 'vendor/Pods/Sparkle/Sparkle.framework'
    @config.pods.pods_libraries

    @config.embedded_frameworks.first.end_with?(sparkle_framework_path).should.equal true
  end

  it 'should create private certificate' do
    File.exist?(@config.sparkle.private_key_path.to_s).should.equal true
  end

  it 'should create public certificate' do
    File.exist?(@config.sparkle.public_key_path.to_s).should.equal true
  end

  it 'should add files to gitignore' do
    a = `cat .gitignore`
    a.strip.should.not.equal ''
  end
end
# rubocop:enable Metrics/BlockLength
