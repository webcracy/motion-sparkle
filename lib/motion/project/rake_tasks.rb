# frozen_string_literal: true

# Sparkle specific rake tasks
# rubocop:disable Metrics/BlockLength
namespace :sparkle do
  desc 'Sparkle Help'
  task :help do
    puts <<~HELP


      During initial Sparkle setup, run these rake tasks:

      1. `rake sparkle:setup_certificates`
      2. `rake sparkle:setup`

      Then after running `rake build:release`, you can run

      3. `rake sparkle:package`            create the zipped package and release notes
      4. `rake sparkle:copy_to_release`    copy package/notes into release folder
      5. `rake sparkle:generate_appcast`   generate the appcast
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

  desc 'Copy the release notes and zip archive to the release folder'
  task :copy_to_release do
    App.config_without_setup.build_mode = :release
    sparkle = App.config.sparkle
    sparkle.copy_to_release
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
# rubocop:enable Metrics/BlockLength
