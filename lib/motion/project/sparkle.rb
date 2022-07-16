# frozen_string_literal: true

module Motion
  module Project
    # rubocop:disable Metrics/ClassLength
    class Sparkle
      SPARKLE_ROOT = 'sparkle'
      CONFIG_PATH = "#{SPARKLE_ROOT}/config"
      RELEASE_PATH = "#{SPARKLE_ROOT}/release"
      EDDSA_PRIV_KEY = 'eddsa_priv.key'
      DSA_PRIV_KEY = 'dsa_priv.pem'

      def initialize(config)
        @config = config
        # verify_installation
      end

      def after_initialize
        self.feed_url = appcast.feed_url
      end

      def appcast
        @appcast ||= Appcast.new(self)
      end

      def publish(key, value)
        return if appcast.process_option(key, value)

        case key
        when :public_key
          self.public_ed_dsa_key = value
        when :version
          version(value)
        else
          raise "Unknown Sparkle config option #{key}"
        end
      end
      alias release publish

      def version(vstring)
        @config.version = vstring.to_s
        @config.short_version = vstring.to_s
      end

      def version_string
        "#{@config.short_version} (#{@config.version})"
      end

      def feed_url
        @config.info_plist['SUFeedURL']
      end

      def feed_url=(url)
        @config.info_plist['SUFeedURL'] = url
      end

      def public_ed_dsa_key
        @config.info_plist['SUPublicEDKey']
      end

      def public_ed_dsa_key=(key)
        @config.info_plist['SUPublicEDKey'] = key
      end

      # File manipulation and certificates

      def add_to_gitignore
        @ignorable = ['sparkle/release', 'sparkle/release/*', private_key_path]
        return unless File.exist?(gitignore_path)

        File.open(gitignore_path, 'r') do |f|
          f.each_line do |line|
            @ignorable.delete(line) if @ignorable.include?(line)
          end
        end
        if @ignorable.any?
          File.open(gitignore_path, 'a') do |f|
            @ignorable.each do |i|
              f << "#{i}\n"
            end
          end
        end
        `cat #{gitignore_path}`
      end

      def create_sparkle_folder
        create_config_folder
        create_release_folder
      end

      def generate_keys_app
        "#{vendored_sparkle_path}/bin/generate_keys"
      end

      # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity, Metrics/MethodLength
      def generate_keys
        return false unless config_ok?

        FileUtils.mkdir_p sparkle_config_path unless File.exist?(sparkle_config_path)

        if appcast.use_exported_private_key && File.exist?(private_key_path)
          App.info 'Sparkle', "Private key already exported at `#{private_key_path}` and will be used."
          if public_ed_dsa_key.present?
            App.info '', <<~EXISTS
              SUPublicEDKey already set

              Be careful not to override or lose your certificates.
              Delete this file if you're sure.
              Aborting (no action performed)
            EXISTS
              .indent(11, skip_first_line: true)
          else
            App.info '', <<~EXISTS
              SUPublicEDKey NOT SET

              You can easily add the `SUPublicEDKey` by publishing the key in your Rakefile:

              app.sparkle do
                ...
                publish :public_key, 'PUBLIC_KEY'
              end

              Be careful not to override or lose your certificates.
              Delete this file if you're sure.
              Aborting (no action performed)
            EXISTS
              .indent(11, skip_first_line: true)
          end

          return
        end

        results, status = Open3.capture2e(generate_keys_app, '-p', '--account', appcast.cli_options[:account])

        if status.success?
          App.info 'Sparkle', "Public/private keys found in the keychain for account #{appcast.cli_options[:account]}"

          if results.strip == public_ed_dsa_key
            App.info 'Sparkle', 'Keychain public key matches `SUPublicEDKey`'

            if appcast.use_exported_private_key && !File.exist?(private_key_path)
              # export the private key from the keychain
            end
          else
            App.fail <<~NOT_MATCHED
              Keychain public key DOES NOT match `SUPublicEDKey`

                  Keychain public key:      #{results.strip}
                  SUPublicEDKey public key: #{public_ed_dsa_key}

            NOT_MATCHED
              .indent(11, skip_first_line: true)
          end

          return
        end

        create_private_key
        export_private_key if appcast.use_exported_private_key
      end
      # rubocop:enable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity, Metrics/MethodLength

      # Create the private key in the keychain
      def create_private_key
        App.info 'Sparkle',
                 'Generating a new signing key into the Keychain. This may take a moment, depending on your machine.'
        results, status = Open3.capture2e(generate_keys_app, '--account', appcast.cli_options[:account])

        App.fail 'Sparkle could not generate keys' unless status.success?

        puts
        puts results.lines[1..].join.indent(11)

        # Extract the public key so we can use it in message
        results, status = Open3.capture2e(generate_keys_app, '-p', '--account', appcast.cli_options[:account])

        App.fail 'Unable to read public key' unless status.success?

        puts <<~KEYS
          You can easily add the `SUPublicEDKey` by publishing the key in your Rakefile:

              app.sparkle do
                ...
                publish :public_key, '#{results.strip}'
              end

        KEYS
          .indent(11)
      end

      # Export the private key from the keychain
      def export_private_key
        _results, status = Open3.capture2e(generate_keys_app, '-x', private_key_path.to_s, '--account', appcast.cli_options[:account])

        App.fail 'Unable to export private key' unless status.success?

        App.info 'Sparkle', 'Private key has been exported from the keychain into the file:'
        puts <<~KEYS

              ./#{private_key_path}

          ADD THIS PRIVATE KEY TO YOUR `.gitignore` OR EQUIVALENT AND BACK IT UP!
          KEEP IT PRIVATE AND SAFE!
          If you lose it, your users will be unable to upgrade, unless you used Apple code signing.
          See https://sparkle-project.org/documentation/ for details
        KEYS
          .indent(11)
      end

      # copy the release notes and zip archive into the releases_folder,
      # where the appcast will get built
      def copy_to_release
        destination_path = (project_path + releases_folder).realpath
        zip_file_path = (sparkle_release_path + zip_file)

        [release_notes_path, zip_file_path].each do |file|
          FileUtils.cp(file, "#{destination_path}/")
          App.info 'Copied', "#{destination_path}/#{file}"
        end
      end

      # Generate the appcast.
      # Note: We do not support the old DSA keys, only the newer EdDSA keys.
      #       See https://sparkle-project.org/documentation/eddsa-migration
      def generate_appcast
        generate_appcast_app = "#{vendored_sparkle_path}/bin/generate_appcast"
        path = (project_path + releases_folder).realpath
        appcast_filename = (path + appcast.feed_filename)
        appcast.cli_options[:output_path] = appcast_filename

        FileUtils.mkdir_p(path) unless File.exist?(path)

        App.info('Sparkle', "Generating appcast using `#{generate_appcast_app}`")
        puts "from files in `#{path}`...".indent(11)

        args = appcast.prepare_args

        App.info 'Executing', [generate_appcast_app, *args, path.to_s].join(' ')

        results, status = Open3.capture2e(generate_appcast_app, *args, path.to_s)

        App.info('Sparkle', "Saved appcast to `#{appcast_filename}`") if status.success?
        puts results.indent(11)

        return unless status.success?

        puts
        puts "SUFeedURL     : #{feed_url}".indent(11)
        puts "SUPublicEDKey : #{public_ed_dsa_key}".indent(11)
      end

      def generate_appcast_help
        generate_appcast_app = "#{vendored_sparkle_path}/bin/generate_appcast"
        results, _status = Open3.capture2e(generate_appcast_app, '--help')

        puts results
      end

      def create_release_notes
        App.fail "Release notes template not found as expected at ./#{release_notes_template_path}" unless File.exist?(release_notes_template_path)

        create_release_folder

        File.open(release_notes_path.to_s, 'w') do |f|
          template = File.read(release_notes_template_path)
          f << ERB.new(template).result(binding)
        end

        App.info 'Create', "./#{release_notes_path}"
      end

      def release_notes_template_path
        sparkle_config_path.join('release_notes.template.erb')
      end

      def release_notes_content_path
        sparkle_config_path.join('release_notes.content.html')
      end

      def release_notes_path
        sparkle_release_path + (appcast.notes_filename || "#{app_name}.#{@config.short_version}.html")
      end

      def release_notes_content
        if File.exist?(release_notes_content_path)
          File.read(release_notes_content_path)
        else
          App.fail "Missing #{release_notes_content_path}"
        end
      end

      def release_notes_html
        release_notes_content
      end

      # A few helpers

      def project_path
        @project_path ||= Pathname.new(@config.project_dir)
      end

      def vendor_path
        @vendor_path ||= project_path.join('vendor')
      end

      def gitignore_path
        project_path.join('.gitignore')
      end

      def sparkle_release_path
        project_path.join(RELEASE_PATH)
      end

      def sparkle_config_path
        project_path.join(CONFIG_PATH)
      end

      def private_key_path
        sparkle_config_path.join(EDDSA_PRIV_KEY)
      end

      def app_bundle_path
        Pathname.new(@config.app_bundle_raw('MacOSX'))
      end

      def app_release_path
        app_bundle_path.parent.to_s
      end

      def app_name
        File.basename(app_bundle_path, '.app')
      end

      def zip_file
        appcast.package_filename || "#{app_name}.#{@config.short_version}.zip"
      end

      def releases_folder
        appcast.releases_folder
      end

      def app_file
        "#{app_name}.app"
      end

      private

      def create_config_folder
        FileUtils.mkdir_p(sparkle_config_path) unless File.exist?(sparkle_config_path)
      end

      def create_release_folder
        FileUtils.mkdir_p(sparkle_release_path) unless File.exist?(sparkle_release_path)
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
