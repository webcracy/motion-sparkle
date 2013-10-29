require File.expand_path('../spec_helper', __FILE__)

module Motion; module Project;
  class Config
    attr_writer :project_dir
  end
end; end

describe "motion-sparkle" do
  extend SpecHelper::TemporaryDirectory

  before do
    unless @completed_setup
      teardown_temporary_directory
      setup_temporary_directory
      FileUtils.mkdir_p(temporary_directory + 'resources')

      @config = App.config
      @config.project_dir = temporary_directory.to_s
      @config.instance_eval do
        sparkle do
          release :base_url, 'http://example.com' 
          release :public_key, 'public_key.pem'
          release :version, '1.0'
        end
      end
    end
  end

  it "Sparkle's release base url should be set correctly" do
    @config.sparkle.appcast.base_url.should.equal 'http://example.com'
  end

  it "Sparkle's feed url should be set correctly" do
    @config.info_plist['SUFeedURL'].should.equal 'http://example.com/releases.xml'
  end

  it "Sparkle's public key should have custom name" do
    @config.info_plist['SUPublicDSAKeyFile'].should.equal 'public_key.pem'
  end

  it "Version and short version should be set correctly" do
    @config.version.should.equal '1.0'
    @config.short_version.should.equal '1.0'
  end

  it "Version should be same for short_version and version" do
    @config.version.should.equal @config.short_version
  end

  it "Sparkle framework should be embedded" do
    sparkle_framework_path = ROOT + "vendor/Sparkle.framework"
    @config.embedded_frameworks.include?(sparkle_framework_path.to_s).should.equal true
  end

  before do
    unless @completed_setup
      Rake::Task['sparkle:setup'].invoke
      Rake::Task['sparkle:setup_certificates'].invoke
      @completed_setup = true
    end
  end

  it "should create private certificate" do
    puts @config.sparkle.private_key_path.to_s
    File.exist?(@config.sparkle.private_key_path.to_s).should.equal true
  end

  it "should create public certificate" do
    puts @config.sparkle.public_key_path.to_s
    File.exist?(@config.sparkle.public_key_path.to_s).should.equal true
  end

end
