# frozen_string_literal: true

require 'open3'

module Motion
  module Project
    class Config
      variable :sparkle

      def sparkle(&block)
        @sparkle ||= Motion::Project::Sparkle.new(self)
        @sparkle.instance_eval(&block) if block
        @sparkle
      end
    end

    class App
      class << self
        def build_with_sparkle(platform, opts = {})
          App.fail 'Sparkle not setup correctly' unless App.config.sparkle.setup_ok?

          App.info 'Sparkle', 'Setup OK'

          build_without_sparkle(platform, opts)
        end

        alias_method 'build_without_sparkle', 'build'
        alias_method 'build', 'build_with_sparkle'
      end
    end

    class Builder
      # The XPC services are already residing in the Sparkle package.  But we need
      # to re-sign the entire package to ensure all executables have the hardened
      # runtime and correct certificate.
      #------------------------------------------------------------------------------
      def codesign_with_sparkle(config, platform)
        if App.config.embedded_frameworks.any? { |item| item.to_s.include?('Sparkle.framework') }
          bundle_path = App.config.app_bundle('MacOSX')
          sparkle_path = File.join(bundle_path, 'Frameworks', 'Sparkle.framework')

          `/usr/bin/codesign -f -s "#{config.codesign_certificate}" -o runtime "#{sparkle_path}/Versions/B/Autoupdate"`
          `/usr/bin/codesign -f -s "#{config.codesign_certificate}" -o runtime "#{sparkle_path}/Versions/B/Updater.app"`
          `/usr/bin/codesign -f -s "#{config.codesign_certificate}" -o runtime "#{sparkle_path}/Versions/B/XPCServices/org.sparkle-project.InstallerLauncher.xpc"`
          `/usr/bin/codesign -f -s "#{config.codesign_certificate}" -o runtime --entitlements "./vendor/Pods/Sparkle/Entitlements/org.sparkle-project.Downloader.entitlements" "#{sparkle_path}/Versions/B/XPCServices/org.sparkle-project.Downloader.xpc"` # rubocop:disable Layout/LineLength

          `/usr/bin/codesign -f -s "#{config.codesign_certificate}" -o runtime "#{sparkle_path}"`
        end

        codesign_without_sparkle(config, platform)
      end

      alias_method 'codesign_without_sparkle', 'codesign'
      alias_method 'codesign', 'codesign_with_sparkle'
    end
  end
end
