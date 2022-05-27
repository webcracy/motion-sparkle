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

module SpecUtils
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
