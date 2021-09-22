require 'open3'

module Motion::Project
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
    # Since we're using the sandboxed version of Sparkle, then we need to copy the
    # xpc services to the proper folder and sign them.  This has to be done
    # before we sign the app itself
    #------------------------------------------------------------------------------
    def codesign_with_sparkle(config, platform)
      if App.config.embedded_frameworks.any? { |item| item.to_s.include?('Sparkle.framework') }
        bundle_path = App.config.app_bundle('MacOSX')

        if File.directory?(App.config.sparkle.vendored_sparkle_xpc_path)

          App.info 'Sparkle', 'Removing unnecessary executables...'
          sparkle_path = File.join(bundle_path, 'Frameworks/Sparkle.framework')
          ['Autoupdate', 'Updater.app', 'Versions/A/Autoupdate', 'Versions/A/Updater.app'].each do |item|
            bundle = File.join(sparkle_path, item)
            FileUtils.rm_r(bundle) if File.exist?(bundle)
          end

          xpc_path = File.join(bundle_path, 'XPCServices')
          App.info 'Sparkle', "Copying XPCServices to #{xpc_path}"

          FileUtils.mkdir_p(xpc_path)
          `cp -R #{App.config.sparkle.vendored_sparkle_xpc_path}/*.xpc "#{xpc_path}"`

          Dir.glob("#{xpc_path}/*.xpc").each do |path|
            App.info 'Codesign', path

            results, _status = Open3.capture2e("#{App.config.sparkle.vendored_sparkle_path}/bin/codesign_xpc_service", App.config.codesign_certificate, File.expand_path(path))

            puts results
          end
        end
      end

      codesign_without_sparkle(config, platform)
    end

    alias_method 'codesign_without_sparkle', 'codesign'
    alias_method 'codesign', 'codesign_with_sparkle'
  end
end
