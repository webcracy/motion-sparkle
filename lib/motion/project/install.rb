module Motion::Project
  class Sparkle
    def vendored_sparkle_path
      Pathname.new(vendor_path + 'Pods/Sparkle')
    end

    def vendored_sparkle_framework_path
      Pathname.new(vendored_sparkle_path + 'Sparkle.framework')
    end

    def vendored_sparkle_xpc_path
      Pathname.new(vendored_sparkle_path + 'XPCServices')
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
