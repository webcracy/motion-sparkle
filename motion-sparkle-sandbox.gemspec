# This is just so that the source file can be loaded.
module ::Motion; module Project; class Config
  def self.variable(*); end
end; end; end

require 'date'
$:.unshift File.expand_path('../lib', __FILE__)

Gem::Specification.new do |spec|
  spec.name        = 'motion-sparkle-sandbox'
  spec.version     = '0.7.0'
  spec.date        = Date.today
  spec.summary     = 'Sparkle (sandboxed) integration for Rubymotion projects'
  spec.description = "motion-sparkle-sandbox makes it easy to use the sandboxed version of Sparkle in your RubyMotion OS X apps"
  spec.author      = 'Brett Walker'
  spec.email       = 'github@digitalmoksha.com'
  spec.homepage    = 'https://github.com/digitalmoksha/motion-sparkle-sandbox'
  spec.license     = 'MIT'
  spec.files       = `git ls-files`.split("\n")
  spec.require_paths = ['lib']
end
