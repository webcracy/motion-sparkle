# frozen_string_literal: true

$:.unshift('/Library/RubyMotion/lib')
$:.unshift(File.expand_path('~/.rubymotion/rubymotion-templates'))
require 'pry-byebug'
require 'rake'

ROOT = Pathname.new(File.expand_path('..', __dir__))

# need to ensure that we bypass the `app.pods` in `lib/motion-sparkle-sandbox.rb`
@running_specs = 1

require 'motion/project/template/osx'
require 'motion-sparkle-sandbox'

# activesupport 4.x uses BigDecimal.new which was removed in bigdecimal 3.0
require 'bigdecimal'
BigDecimal.singleton_class.define_method(:new) { |*a| BigDecimal(*a) } unless BigDecimal.respond_to?(:new)

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
