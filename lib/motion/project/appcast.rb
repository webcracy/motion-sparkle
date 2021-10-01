module Motion::Project
  class Sparkle
    # Generate the appcast.
    # Note: We do not support the old DSA keys, only the newer EdDSA keys.
    #       See https://sparkle-project.org/documentation/eddsa-migration
    def generate_appcast
      generate_appcast_app = "#{vendored_sparkle_path}/bin/generate_appcast"
      path = (project_path + archive_folder).realpath
      appcast_filename = (path + appcast.feed_filename)

      args = []

      FileUtils.mkdir_p(path) unless File.exist?(path)

      App.info('Sparkle', "Generating appcast using `#{generate_appcast_app}`")
      puts "from files in `#{path}`...".indent(11)

      if appcast.use_exported_private_key && File.exist?(private_key_path)
        # -s <private-EdDSA-key>  The private EdDSA string (128 characters). If not
        #                         specified, the private EdDSA key will be read from
        #                         the Keychain instead.
        private_key = File.read(private_key_path)
        args << "-s=#{private_key}"
      end

      # --download-url-prefix <url> A URL that will be used as prefix for the URL from
      #                             where updates will be downloaded.
      args << "--download-url-prefix=#{appcast.package_url}" if appcast.package_url.present?

      # --release-notes-url-prefix <url> A URL that will be used as prefix for constructing
      #                                  URLs for release notes.
      args << "--release-notes-url-prefix=#{appcast.notes_url}" if appcast.notes_url.present?

      # --link <link>           A URL to the application's website which Sparkle may
      #                         use for directing users to if they cannot download a
      #                         new update from within the application. This will be
      #                         used for new generated update items. By default, no
      #                         product link is used.

      # --versions <versions>   An optional comma delimited list of application
      #                         versions (specified by CFBundleVersion) to generate
      #                         new update items for. By default, new update items
      #                         are inferred from the available archives and are only
      #                         generated if they are in the latest 5 updates in the
      #                         appcast.

      # --maximum-deltas <maximum-deltas>
      #                         The maximum number of delta items to create for the
      #                         latest update for each minimum required operating
      #                         system. (default: 5)

      # --channel <channel-name>
      #                         The Sparkle channel name that will be used for
      #                         generating new updates. By default, no channel is
      #                         used. Old applications need to be using Sparkle 2 to
      #                         use this feature.

      # --major-version <major-version>
      #                         The last major or minimum autoupdate sparkle:version
      #                         that will be used for generating new updates. By
      #                         default, no last major version is used.

      # --phased-rollout-interval <phased-rollout-interval>
      #                         The phased rollout interval in seconds that will be
      #                         used for generating new updates. By default, no
      #                         phased rollout interval is used.

      # --critical-update-version <critical-update-version>
      #                         The last critical update sparkle:version that will be
      #                         used for generating new updates. An empty string
      #                         argument will treat this update as critical coming
      #                         from any application version. By default, no last
      #                         critical update version is used. Old applications
      #                         need to be using Sparkle 2 to use this feature.

      # --informational-update-versions <informational-update-versions>
      #                         A comma delimited list of application
      #                         sparkle:version's that will see newly generated
      #                         updates as being informational only. An empty string
      #                         argument will treat this update as informational
      #                         coming from any application version. By default,
      #                         updates are not informational only. --link must also
      #                         be provided. Old applications need to be using
      #                         Sparkle 2 to use this feature.

      # -o <output-path>        Path to filename for the generated appcast (allowed
      #                         when only one will be created).

      # -f <private-dsa-key-file> Path to the private DSA key file. Only use this
      #                           option for transitioning to EdDSA from older updates.
      # Note: only for supporting a legacy app that used DSA keys.  Check if the
      # default DSA key exists in `sparkle/config/dsa_priv.pem` and if it does,
      # add it to the command.
      if File.exist?(legacy_private_key_path)
        App.info 'Sparkle', "Also signing with legacy DSA key at #{legacy_private_key_path}"
        args << "-f=#{legacy_private_key_path}"
      end

      args << "-o=#{appcast_filename}" if appcast_filename.present?

      App.info 'Executing', [generate_appcast_app, *args, path.to_s].join(' ')

      results, status = Open3.capture2e(generate_appcast_app, *args, path.to_s)

      App.info('Sparkle', "Saved appcast to `#{appcast_filename}`") if status.success?
      puts results.indent(11)

      if status.success?
        puts
        puts "SUFeedURL     : #{feed_url}".indent(11)
        puts "SUPublicEDKey : #{public_EdDSA_key}".indent(11)
      end
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
      sparkle_config_path + 'release_notes.template.erb'
    end

    def release_notes_content_path
      sparkle_config_path + 'release_notes.content.html'
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

    class Appcast
      attr_accessor :base_url,
                    :feed_base_url,
                    :feed_filename,
                    :notes_base_url,
                    :notes_filename,
                    :package_base_url,
                    :package_filename,
                    :archive_folder,
                    :use_exported_private_key

      def initialize
        @feed_base_url = nil
        @feed_filename = 'releases.xml'
        @notes_base_url = nil
        @notes_filename = nil
        @package_base_url = nil
        @package_filename = nil
        @base_url = nil
        @archive_folder = nil
        @use_exported_private_key = false
      end

      def feed_url
        "#{feed_base_url || base_url}#{feed_filename}"
      end

      def notes_url
        notes_base_url || base_url
      end

      def package_url
        package_base_url || base_url
      end
    end
  end
end
