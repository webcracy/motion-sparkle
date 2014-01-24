module Motion::Project
  class Sparkle

    def package
      return unless setup_ok?
      create_release_folder
      @config.build_mode = :release
      return unless create_zip_file
      App.info "Release", version_string
      App.info "Version", @config.version
      App.info "Build", @config.short_version || 'unspecified in Rakefile'
      App.info "Size", @package_size.to_s
      sign_package
      create_appcast
      create_release_notes
      `open #{sparkle_release_path}`
    end

    def create_zip_file
      unless File.exist?(app_bundle_path)
        App.fail "You need to build your app with the Release target to use Sparkle"
      end
      if File.exist?("#{sparkle_release_path}/#{zip_file}")
        App.fail "Release already exists at ./#{sparkle_release_path}/#{zip_file} (remove it manually with `rake sparkle:clean`)"
      end
      FileUtils.cd(app_release_path) do
        `zip -r --symlinks "#{zip_file}" "#{app_file}"`
      end
      FileUtils.mv "#{app_release_path}/#{zip_file}", "./#{sparkle_release_path}/"
      App.info "Create", "./#{sparkle_release_path}/#{zip_file}"
      @package_file = zip_file
      @package_size = File.size "./#{sparkle_release_path}/#{zip_file}"
    end

    def sign_package
      package = "./#{sparkle_release_path}/#{zip_file}"
      @package_signature = `#{openssl} dgst -sha1 -binary < "#{package}" | #{openssl} dgst -dss1 -sign "#{private_key_path}" | #{openssl} enc -base64`
      @package_signature = @package_signature.strip
      App.info "Signature", "\"#{@package_signature}\""
    end


  end
end
