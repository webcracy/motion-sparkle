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

      def appcast
        @appcast ||= Appcast.new
      end

      def publish(key, value)
        case key
        when :public_key
          self.public_EdDSA_key = value
        when :base_url
          appcast.base_url = value
          self.feed_url = appcast.feed_url
        when :feed_base_url
          appcast.feed_base_url = value
          self.feed_url = appcast.feed_url
        when :feed_filename
          appcast.feed_filename = value
          self.feed_url = appcast.feed_url
        when :version
          version value
        when :package_base_url, :package_filename, :notes_base_url, :notes_filename, :use_exported_private_key
          appcast.send "#{key}=", value
        when :archive_folder
          appcast.archive_folder = value
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

      # rubocop:disable Naming/MethodName
      def public_EdDSA_key
        @config.info_plist['SUPublicEDKey']
      end

      def public_EdDSA_key=(key)
        @config.info_plist['SUPublicEDKey'] = key
      end
      # rubocop:enable Naming/MethodName

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
          if public_EdDSA_key.present?
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

        results, status = Open3.capture2e(generate_keys_app, '-p')

        if status.success?
          App.info 'Sparkle', 'Public/private keys found in the keychain'

          if results.strip == public_EdDSA_key
            App.info 'Sparkle', 'Keychain public key matches `SUPublicEDKey`'

            if appcast.use_exported_private_key && !File.exist?(private_key_path)
              # export the private key from the keychain
            end
          else
            App.fail <<~NOT_MATCHED
              Keychain public key DOES NOT match `SUPublicEDKey`

                  Keychain public key:      #{results.strip}
                  SUPublicEDKey public key: #{public_EdDSA_key}

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
        results, status = Open3.capture2e(generate_keys_app)

        App.fail 'Sparkle could not generate keys' unless status.success?

        puts
        puts results.lines[1..].join.indent(11)

        # Extract the public key so we can use it in message
        results, status = Open3.capture2e(generate_keys_app, '-p')

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
        _results, status = Open3.capture2e(generate_keys_app, '-x', private_key_path.to_s)

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

      def legacy_private_key_path
        sparkle_config_path.join(DSA_PRIV_KEY)
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

      def archive_folder
        appcast.archive_folder
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
