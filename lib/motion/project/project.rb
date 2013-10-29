module Motion::Project

  class Config
    variable :sparkle

    def sparkle(&block)
      @sparkle ||= Motion::Project::Sparkle.new(self)
      if block
        @sparkle.instance_eval &block
      end
      @sparkle
    end
  end

  class App
    class << self
      def build_with_sparkle(platform, opts = {})
        if App.config.sparkle.setup_ok?
          App.info "Sparkle", "Setup OK"
        else
          exit 1
        end
        build_without_sparkle(platform, opts)
      end

      alias_method "build_without_sparkle", "build"
      alias_method "build", "build_with_sparkle"
    end
  end

  # In 10.9, `codesign` no longer uses the `--deep` flag by default
  # To make sure `Sparkle.framework` is signed, we need to override 
  # this part of the RubyMotion build process to pass it
  # FIXME: this will probably be taken care of upstream
  class Builder
    def codesign(config, platform)
      app_bundle = config.app_bundle_raw('MacOSX')
      entitlements = File.join(config.versionized_build_dir(platform), "Entitlements.plist")
      if File.mtime(config.project_file) > File.mtime(app_bundle) \
          or !system("/usr/bin/codesign --verify \"#{app_bundle}\" >& /dev/null")
        App.info 'Codesign', app_bundle
        File.open(entitlements, 'w') { |io| io.write(config.entitlements_data) }
        sh "/usr/bin/codesign --deep --force --sign \"#{config.codesign_certificate}\" --entitlements \"#{entitlements}\" \"#{app_bundle}\""
      end
    end
  end
end
