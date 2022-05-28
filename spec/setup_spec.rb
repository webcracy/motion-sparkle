# frozen_string_literal: true

require File.expand_path('spec_utils', __dir__)

describe 'Sparkle setup' do
  before(:all) do
    @config = App.config
    @config.project_dir = SpecUtils::TemporaryDirectory.directory.to_s
    @config.instance_eval do
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

    Rake::Task['sparkle:setup'].invoke
  end

  # it 'should create private certificate' do
  #   expect(File.exist?(@config.sparkle.private_key_path.to_s)).to be_truthy
  # end
  #
  # it 'should create public certificate' do
  #   expect(File.exist?(@config.sparkle.public_key_path.to_s)).to be_truthy
  # end

  it 'should add files to gitignore' do
    a = `cat .gitignore`
    expect(a.strip).not_to eq ''
  end
end
