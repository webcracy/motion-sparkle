# frozen_string_literal: true

module Motion
  module Project
    # This is just so that the source file can be loaded
    class Config
      def self.variable(*); end
    end
  end
end

# require 'date'
# $:.unshift File.expand_path('../lib', __FILE__)
require File.expand_path('lib/motion-sparkle-sandbox/version.rb', __dir__)

Gem::Specification.new do |spec|
  spec.name          = 'motion-sparkle-sandbox'
  spec.version       = MotionSparkleSandbox::VERSION
  spec.authors       = ['Brett Walker', 'Alexandre L. Solleiro']
  spec.email         = ['github@digitalmoksha.com', 'alex@webcracy.org']
  spec.summary       = 'Sparkle (sandboxed) integration for Rubymotion projects'
  spec.description   = 'motion-sparkle-sandbox makes it easy to use the sandboxed version of Sparkle in your RubyMotion macOS apps'
  spec.homepage      = 'https://github.com/digitalmoksha/motion-sparkle-sandbox'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split("\n")
  spec.test_files    = Dir.glob('spec/**/*.rb')
  spec.require_paths = ['lib']

  spec.add_dependency 'motion-cocoapods'
end
