# frozen_string_literal: true

# Sparkle specific rake tasks
namespace :sparkle do
  desc 'Sparkle Help'
  task :help do
    puts <<~HELP
      During initial Sparkle setup, run these rake tasks:

      1. `rake sparkle:setup_certificates`
      2. `rake sparkle:setup`

      Then after running `rake build:release`, you can run
      `rake sparkle:package`
    HELP
  end

  desc 'Setup Sparkle configuration'
  task :setup do
    sparkle = App.config.sparkle
    sparkle.setup
  end

  desc 'Create a ZIP file with your application .app release build'
  task :package do
    App.config_without_setup.build_mode = :release
    sparkle = App.config.sparkle
    sparkle.package
  end

  task :setup_certificates do
    sparkle = App.config.sparkle
    sparkle.generate_keys
  end

  desc 'Generate the EdDSA signature for a package'
  task :sign do
    App.config_without_setup.build_mode = :release
    sparkle = App.config.sparkle
    sparkle.sign_package
  end

  desc "Generate the appcast xml feed using Sparkle's `generate_appcast`"
  task :generate_appcast do
    App.config_without_setup.build_mode = :release
    sparkle = App.config.sparkle
    sparkle.generate_appcast
  end

  namespace :generate_appcast do
    desc "Show help for Sparkle's `generate_appcast`"
    task :help do
      App.config_without_setup.build_mode = :release
      sparkle = App.config.sparkle
      sparkle.generate_appcast_help
    end
  end

  desc 'Update the release notes of this build'
  task :release_notes do
    App.config_without_setup.build_mode = :release
    sparkle = App.config.sparkle
    sparkle.create_release_notes
  end

  desc 'Clean the Sparkle release folder'
  task :clean do
    dir = Motion::Project::Sparkle::RELEASE_PATH
    if File.exist?("./#{dir}")
      App.info 'Delete', "./#{dir}"
      rm_rf dir
    end
  end
end

namespace :clean do
  # Delete Sparkle release folder when cleaning all
  task :all do
    dir = Motion::Project::Sparkle::RELEASE_PATH
    if File.exist?("./#{dir}")
      App.info 'Delete', "./#{dir}"
      rm_rf dir
    end
  end
end
