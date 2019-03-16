module Motion::Project
  class Sparkle

    SPARKLE_ZIP_FILE = 'Sparkle.zip'

    def sparkle_distrib
      file_path = Pathname.new File.dirname(__FILE__)
      distrib_path = "vendor/#{SPARKLE_ZIP_FILE}"
      (file_path.parent.parent.parent + distrib_path).to_s
      Pathname.new(sparkle_vendor_path + SPARKLE_ZIP_FILE)
    end

    def sparkle_vendor_path
      file_path = Pathname.new File.dirname(__FILE__)
      (file_path.parent.parent.parent + 'vendor/').to_s
    end

    def sparkle_path
      Pathname.new(vendor_path + 'Sparkle')
    end

    def sparkle_framework_path
      Pathname.new(vendor_path + 'Sparkle/Sparkle.framework')
    end

    def sparkle_xpc_path
      Pathname.new(vendor_path + 'Sparkle/XPCServices')
    end

    def sparkle_zipball
      Pathname.new(vendor_path + SPARKLE_ZIP_FILE)
    end

    def copy_zipball
      `cp #{sparkle_distrib} #{sparkle_zipball}`
    end

    def unzip
      `unzip #{sparkle_zipball.to_s} -d #{vendor_path.to_s}`
      `rm #{sparkle_zipball}`
    end

    def installed?
      File.directory?(sparkle_framework_path)
    end

    def install
      FileUtils.rm_rf(sparkle_path) if File.directory?(sparkle_path) # force clean install
      copy_zipball
      unzip
    end

    def embed
      @config.embedded_frameworks << sparkle_framework_path
    end

    def install_and_embed
      install unless installed?
      embed
    end

    def verify_installation
      if installed?
        App.info "Sparkle", "Framework installed in #{sparkle_framework_path.to_s}"
      else
        App.fail "Sparkle framework not correctly copied to #{sparkle_framework_path.to_s}
Run `rake sparkle:install` manually or, if the problem persists,
please explain your setup and problem as an issue on GitHub at:
https://github.com/webcracy/motion-sparkle/issues
"
      end
    end

  end
end
