# frozen_string_literal: true

raise 'This file must be required within a RubyMotion project Rakefile.' unless defined?(Motion::Project::Config)

require 'motion-cocoapods'

require 'motion/project/sparkle'
require 'motion/project/install'
require 'motion/project/setup'
require 'motion/project/package'
require 'motion/project/templates'
require 'motion/project/appcast'
require 'motion/project/project'
require 'motion/project/rake_tasks'

lib_dir_path = File.dirname(File.expand_path(__FILE__))

POD_VERSION = '~> 2.0.0-beta.3'

unless @running_specs
  Motion::Project::App.setup do |app|
    app.files.unshift(Dir.glob(File.join(lib_dir_path, 'motion-sparkle-sandbox/**/*.rb')))
    app.pods do
      pod 'Sparkle', POD_VERSION
    end
  end
end
