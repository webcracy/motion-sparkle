module Motion::Project
  class Sparkle

    def sparkle_distrib
      file_path = Pathname.new File.dirname(__FILE__)
      distrib_path = 'vendor/Sparkle.framework.zip'
      (file_path.parent.parent.parent + distrib_path).to_s
    end

    def sparkle_path
      Pathname.new(vendor_path + 'Sparkle.framework')
    end

    def sparkle_zipball
      Pathname.new(vendor_path + 'Sparkle.framework.zip')
    end

    def copy_zipball
      `cp #{sparkle_distrib} #{sparkle_zipball}`
    end

    def unzip
      `unzip #{sparkle_zipball.to_s} -d #{vendor_path.to_s}`
      `rm #{sparkle_zipball}`
    end

    def installed?
      File.directory?(sparkle_path)
    end

    def install
      copy_zipball
      unzip
    end

    def embed
      @config.embedded_frameworks << sparkle_path
    end

    def install_and_embed
      install unless installed?
      embed
    end

    def verify_installation
      if installed?
        App.info "Sparkle", "Framework installed in #{sparkle_path.to_s}"
      else
        App.fail "Sparkle framework not correctly copied to #{sparkle_path.to_s}
Run `rake sparkle:install` manually or, if the problem persists, 
please explain your setup and problem as an issue on GitHub at:
https://github.com/webcracy/motion-sparkle/issues
"
      end
    end

  end
end
