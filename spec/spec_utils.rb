# frozen_string_literal: true

require 'rake'
require 'pry'

ROOT = Pathname.new(File.expand_path('..', __dir__))
$:.unshift(ENV['RUBYMOTION_CHECKOUT'] || '/Library/RubyMotion/lib')
$:.unshift("#{ROOT}lib".to_s)

# need to ensure that we bypass the `app.pods` in `lib/motion-sparkle-sandbox.rb`
@running_specs = 1

require 'motion/project/template/osx'
require 'motion-sparkle-sandbox'

# necessary for us to be able to overwrite the `project_dir`
module Motion
  module Project
    class Config
      attr_writer :project_dir
    end
  end
end

module SpecUtils
  module SparkleSetup
    # run from a before(:suite)
    def self.initial_install
      SpecUtils::TemporaryDirectory.setup

      FileUtils.mkdir_p("#{SpecUtils::TemporaryDirectory.directory}/resources")
      FileUtils.mkdir_p("#{SpecUtils::TemporaryDirectory.directory}/vendor")
      FileUtils.touch("#{SpecUtils::TemporaryDirectory.directory}/.gitignore")

      @config = App.config
      @config.sparkle = nil
      @config.project_dir = SpecUtils::TemporaryDirectory.directory.to_s
      @config.instance_eval do
        pods do
          pod 'Sparkle', POD_VERSION
        end
      end

      Rake::Task['pod:install'].invoke
    end

    # run from an after(:suite)
    def self.final_deinstall
      SpecUtils::TemporaryDirectory.teardown
    end
  end

  module TemporaryDirectory
    TEMPORARY_DIRECTORY = ROOT + 'tmp' # rubocop:disable Style/StringConcatenation

    def self.directory
      TEMPORARY_DIRECTORY
    end

    def self.setup
      directory.mkpath
    end

    def self.teardown
      directory.rmtree if directory.exist?
    end
  end
end
