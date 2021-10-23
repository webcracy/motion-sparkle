# frozen_string_literal: true

module Motion
  module Project
    class Sparkle
      def vendored_sparkle_path
        vendor_path.join('Pods/Sparkle')
      end

      def vendored_sparkle_framework_path
        vendored_sparkle_path.join('Sparkle.framework')
      end

      def vendored_sparkle_xpc_path
        vendored_sparkle_path.join('XPCServices')
      end

      def installed?
        File.directory?(vendored_sparkle_framework_path)
      end

      def verify_installation
        if installed?
          App.info 'Sparkle', "Framework installed in #{vendored_sparkle_framework_path}"
        else
          App.fail "Sparkle Cocoapod not correctly installed to #{vendored_sparkle_path}. Run `rake pod:install`."
        end
      end
    end
  end
end
