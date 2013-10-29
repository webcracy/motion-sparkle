# This is just so that the source file can be loaded.
module ::Motion; module Project; class Config
  def self.variable(*); end
end; end; end

require 'date'
$:.unshift File.expand_path('../lib', __FILE__)
require 'motion/project/version'

Gem::Specification.new do |spec|
  spec.name        = 'motion-sparkle'
  spec.version     = Motion::Project::Sparkle::VERSION
  spec.date        = Date.today
  spec.summary     = 'Sparkle integration for Rubymotion projects'
  spec.description = "motion-sparkle makes it easy to use Sparkle with your RubyMotion projects"
  spec.author      = 'Alexandre L. Solleiro'
  spec.email       = 'alex@webcracy.org'
  spec.homepage    = 'https://github.com/webcracy/motion-sparkle'
  spec.license     = 'MIT'
  spec.files       = `git ls-files`.split("\n")
  spec.require_paths = ['lib']
end
