# Rake tasks
namespace :sparkle do

  task :install do
    sparkle = App.config.sparkle
    sparkle.install
  end

  desc "Setup Sparkle configuration"
  task :setup do
    sparkle = App.config.sparkle
    sparkle.setup
  end

  desc "Create a ZIP file with you application .app release build"
  task :package do
    App.config_without_setup.build_mode = :release
    sparkle = App.config.sparkle
    sparkle.package
  end

  task :setup_certificates do
    sparkle = App.config.sparkle
    sparkle.generate_keys
  end

  desc "Sign the ZIP file with appropriate certificates"
  task :sign do
    App.config_without_setup.build_mode = :release
    sparkle = App.config.sparkle
    sparkle.sign_package
  end

  task :recreate_public_key do
    sparkle = App.config.sparkle
    sparkle.generate_public_key
  end

  task :copy_release_notes_templates do
    App.config_without_setup.build_mode = :release
    sparkle = App.config.sparkle
    sparkle.copy_templates(force = true)
  end

  desc "Generate the appcast xml feed"
  task :feed do
    App.config_without_setup.build_mode = :release
    sparkle = App.config.sparkle
    sparkle.create_appcast
  end

  desc "Generate the appcast using Sparkle's `generate_appcast`"
  task :generate_appcast do
    App.config_without_setup.build_mode = :release
    sparkle = App.config.sparkle
    results = `#{sparkle.sparkle_vendor_path}/generate_appcast -f "#{sparkle.private_key_path}" "#{sparkle.archive_folder}"`
  end

  desc "Update the release notes of this build"
  task :release_notes do
    App.config_without_setup.build_mode = :release
    sparkle = App.config.sparkle
    sparkle.create_release_notes
  end

  desc "Upload to configured location"
  task :upload do
  end

  desc "Clean the Sparkle release folder"
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
