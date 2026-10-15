# frozen_string_literal: true

# rubocop:disable-next Metrics/ClassLength
module Motion
  module Project
    class Sparkle
      class Appcast
        PARAMS = %i[
          package_base_url
          package_filename
          notes_base_url
          notes_filename
          use_exported_private_key
          base_url
          releases_folder
          feed_base_url
          feed_filename
        ].freeze

        CLI_OPTIONS = {
          account: '--account',
          private_ed_key_file: '--ed-key-file',
          download_url_prefix: '--download-url-prefix',
          release_notes_url_prefix: '--release-notes-url-prefix',
          full_release_notes_url: '--full-release-notes-url',
          link: '--link',
          versions: '--versions',
          maximum_deltas: '--maximum-deltas',
          delta_compression: '--delta-compression',
          delta_compression_level: '--delta-compression-level',
          channel: '--channel',
          major_version: '--major-version',
          ignore_skipped_upgrades_below_version: '--ignore-skipped-upgrades-below-version',
          phased_rollout_interval: '--phased-rollout-interval',
          critical_update_version: '--critical-update-version',
          informational_update_versions: '--informational-update-versions',
          output_path: '-o'
        }.freeze

        attr_accessor :base_url,
                      :feed_base_url,
                      :feed_filename,
                      :notes_filename,
                      :package_filename,
                      :releases_folder,
                      :use_exported_private_key,
                      :cli_options
        attr_writer   :notes_base_url,
                      :package_base_url

        def initialize(sparkle_object)
          @sparkle = sparkle_object
          @cli_options = {
            account: 'ed25519' # Sparkle's default account
          }

          @feed_base_url = nil
          @feed_filename = 'releases.xml'
          @notes_base_url = nil
          @notes_filename = nil
          @package_base_url = nil
          @package_filename = nil
          @base_url = nil
          @releases_folder = nil
          @use_exported_private_key = false
        end

        def process_option?(key, value)
          if CLI_OPTIONS.keys.include?(key)
            cli_options[key] = value
          elsif PARAMS.include?(key)
            send("#{key}=", value)
          else
            return false
          end

          true
        end

        def feed_url
          "#{feed_base_url || base_url}#{feed_filename}"
        end

        def notes_base_url
          @notes_base_url || base_url
        end

        def package_base_url
          @package_base_url || base_url
        end

        def prepare_args
          args = []

          account(args)
          private_ed_key_file(args)
          download_url_prefix(args)
          release_notes_url_prefix(args)
          full_release_notes_url(args)
          link(args)
          versions(args)
          maximum_deltas(args)
          delta_compression(args)
          delta_compression_level(args)
          channel(args)
          major_version(args)
          ignore_skipped_upgrades_below_version(args)
          phased_rollout_interval(args)
          critical_update_version(args)
          informational_update_versions(args)
          output_path(args)

          args
        end

        private

        # --account <account>     The account name in your keychain associated with
        #                         your private EdDSA (ed25519) key to use for signing
        #                         new updates. (default: ed25519)
        def account(args)
          return unless cli_options[:account].present?

          args << "--account=#{cli_options[:account]}"
        end

        # -s <private-EdDSA-key>  The private EdDSA string (128 characters). If not
        #                         specified, the private EdDSA key will be read from
        #                         the Keychain instead.
        def private_ed_key_file(args)
          if cli_options[:private_ed_key_file].present?
            args << "--ed-key-file=#{cli_options[:private_ed_key_file]}"
          elsif use_exported_private_key && File.exist?(@sparkle.private_key_path)
            args << "--ed-key-file=#{@sparkle.private_key_path}"
          end
        end

        # --download-url-prefix <url> A URL that will be used as prefix for the URL from
        #                             where updates will be downloaded.
        def download_url_prefix(args)
          if cli_options[:download_url_prefix].present?
            args << "--download-url-prefix=#{cli_options[:download_url_prefix]}"
          elsif package_base_url.present?
            args << "--download-url-prefix=#{package_base_url}"
          end
        end

        # --release-notes-url-prefix <url> A URL that will be used as prefix for constructing
        #                                  URLs for release notes.
        def release_notes_url_prefix(args)
          if cli_options[:release_notes_url_prefix].present?
            args << "--release-notes-url-prefix=#{cli_options[:release_notes_url_prefix]}"
          elsif notes_base_url.present?
            args << "--release-notes-url-prefix=#{notes_base_url}"
          end
        end

        # --full-release-notes-url <url>
        #                         A URL that will be used for the full release notes.
        def full_release_notes_url(args)
          return unless cli_options[:full_release_notes_url].present?

          args << "--full-release-notes-url=#{cli_options[:full_release_notes_url]}"
        end

        # --link <link>           A URL to the application's website which Sparkle may
        #                         use for directing users to if they cannot download a
        #                         new update from within the application. This will be
        #                         used for new generated update items. By default, no
        #                         product link is used.
        def link(args)
          return unless cli_options[:link].present?

          args << "--link=#{cli_options[:link]}"
        end

        # --versions <versions>   An optional comma delimited list of application
        #                         versions (specified by CFBundleVersion) to generate
        #                         new update items for. By default, new update items
        #                         are inferred from the available archives and are only
        #                         generated if they are in the latest 5 updates in the
        #                         appcast.
        def versions(args)
          return unless cli_options[:versions].present?

          args << "--versions=#{cli_options[:versions]}"
        end

        # --maximum-deltas <maximum-deltas>
        #                         The maximum number of delta items to create for the
        #                         latest update for each minimum required operating
        #                         system. (default: 5)
        def maximum_deltas(args)
          return unless cli_options[:maximum_deltas].present?

          args << "--maximum-deltas=#{cli_options[:maximum_deltas]}"
        end

        # --delta-compression <delta-compression>
        #                         The compression method to use for generating delta
        #                         updates. Supported methods for version 3 delta files
        #                         are 'lzma', 'bzip2', 'zlib', 'lzfse', 'lz4', 'none',
        #                         and 'default'. Note that version 2 delta files only
        #                         support 'bzip2', 'none', and 'default' so other
        #                         methods will be ignored if version 2 files are being
        #                         generated. The 'default' compression for version 3
        #                         delta files is currently lzma. (default: default)
        def delta_compression(args)
          return unless cli_options[:delta_compression].present?

          args << "--delta-compression=#{cli_options[:delta_compression]}"
        end

        # --delta-compression-level <delta-compression-level>
        #                         The compression level to use for generating delta
        #                         updates. This only applies if the compression method
        #                         used is bzip2 which accepts values from 1 - 9. A
        #                         special value of 0 will use the default compression
        #                         level. (default: 0)
        def delta_compression_level(args)
          return unless cli_options[:delta_compression_level].present?

          args << "--delta-compression-level=#{cli_options[:delta_compression_level]}"
        end

        # --channel <channel-name>
        #                         The Sparkle channel name that will be used for
        #                         generating new updates. By default, no channel is
        #                         used. Old applications need to be using Sparkle 2 to
        #                         use this feature.
        def channel(args)
          return unless cli_options[:channel].present?

          args << "--channel=#{cli_options[:channel]}"
        end

        # --major-version <major-version>
        #                         The last major or minimum autoupdate sparkle:version
        #                         that will be used for generating new updates. By
        #                         default, no last major version is used.
        def major_version(args)
          return unless cli_options[:major_version].present?

          args << "--major-version=#{cli_options[:major_version]}"
        end

        # --ignore-skipped-upgrades-below-version <below-version>
        #                         Ignore skipped major upgrades below this specified
        #                         version. Only applicable for major upgrades.
        def ignore_skipped_upgrades_below_version(args)
          return unless cli_options[:ignore_skipped_upgrades_below_version].present?

          args << "--ignore-skipped-upgrades-below-version=#{cli_options[:ignore_skipped_upgrades_below_version]}"
        end

        # --phased-rollout-interval <phased-rollout-interval>
        #                         The phased rollout interval in seconds that will be
        #                         used for generating new updates. By default, no
        #                         phased rollout interval is used.
        def phased_rollout_interval(args)
          return unless cli_options[:phased_rollout_interval].present?

          args << "--phased-rollout-interval=#{cli_options[:phased_rollout_interval]}"
        end

        # --critical-update-version <critical-update-version>
        #                         The last critical update sparkle:version that will be
        #                         used for generating new updates. An empty string
        #                         argument will treat this update as critical coming
        #                         from any application version. By default, no last
        #                         critical update version is used. Old applications
        #                         need to be using Sparkle 2 to use this feature.
        def critical_update_version(args)
          return unless cli_options[:critical_update_version].present?

          args << "--critical-update-version=#{cli_options[:critical_update_version]}"
        end

        # --informational-update-versions <informational-update-versions>
        #                         A comma delimited list of application
        #                         sparkle:version's that will see newly generated
        #                         updates as being informational only. An empty string
        #                         argument will treat this update as informational
        #                         coming from any application version. Prefix a version
        #                         string with '<' to indicate (eg "<2.5") to indicate
        #                         older versions than the one specified should treat
        #                         the update as informational only. By default, updates
        #                         are not informational only. --link must also be
        #                         provided. Old applications need to be using Sparkle 2
        #                         to use this feature, and 2.1 or later to use the '<'
        #                         upper bound feature.
        def informational_update_versions(args)
          return unless cli_options[:informational_update_versions].present?

          args << "--informational-update-versions=#{cli_options[:informational_update_versions]}"
        end

        # -o <output-path>        Path to filename for the generated appcast (allowed
        #                         when only one will be created).
        def output_path(args)
          return unless cli_options[:output_path].present?

          args << "-o=#{cli_options[:output_path]}"
        end
      end
    end
  end
end
