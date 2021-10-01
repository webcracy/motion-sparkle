module Motion::Project
  class Sparkle
    def package
      return unless setup_ok?

      create_release_folder
      @config.build_mode = :release
      return unless create_zip_file

      App.info 'Release', version_string
      App.info 'Version', @config.short_version
      App.info 'Build', @config.version || 'unspecified in Rakefile'
      App.info 'Size', @package_size.to_s

      sign_package
      create_release_notes

      `open #{sparkle_release_path}`
    end

    def create_zip_file
      App.fail 'You need to build your app with the Release target to use Sparkle' unless File.exist?(app_bundle_path)

      App.info 'Create', "./#{sparkle_release_path}/#{zip_file}"

      if File.exist?("#{sparkle_release_path}/#{zip_file}")
        App.fail "Release already exists at ./#{sparkle_release_path}/#{zip_file} (remove it manually with `rake sparkle:clean`)"
      end

      FileUtils.cd(app_release_path) do
        `zip -r --symlinks "#{zip_file}" "#{app_file}"`
      end

      FileUtils.mv "#{app_release_path}/#{zip_file}", "./#{sparkle_release_path}/"

      @package_file = zip_file
      @package_size = File.size "./#{sparkle_release_path}/#{zip_file}"
    end

    def sign_package
      package = "./#{sparkle_release_path}/#{zip_file}"
      sign_update_app = "#{vendored_sparkle_path}/bin/sign_update"
      args = []

      if appcast.use_exported_private_key && File.exist?(private_key_path)
        # -s <private-key>        The private EdDSA (ed25519) key
        private_key = File.read(private_key_path)
        args << "-s=#{private_key}"
      end

      results, _status = Open3.capture2e(sign_update_app, *args, package)

      App.info 'Signature', results
    end
  end
end
