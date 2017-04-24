unless defined?(Motion::Project::Config)
  raise "This file must be required within a RubyMotion project Rakefile."
end
require 'motion/project/sparkle'
require 'motion/project/install'
require 'motion/project/setup'
require 'motion/project/package'
require 'motion/project/templates'
require 'motion/project/appcast'
require 'motion/project/project'
require 'motion/project/rake_tasks'
