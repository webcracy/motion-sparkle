module Motion::Project
  class Sparkle

    SPARKLE_ROOT = "sparkle"
    CONFIG_PATH = "#{SPARKLE_ROOT}/config"
    RELEASE_PATH = "#{SPARKLE_ROOT}/release"

    def initialize(config)
      @config = config
      publish :public_key, 'dsa_pub.pem'
      install_and_embed
    end

    def appcast
      @appcast ||= Appcast.new
    end

    def publish(key, value)
      case key
      when :public_key
        public_key value
      when :base_url
        appcast.base_url = value
        feed_url appcast.feed_url
      when :feed_base_url
        appcast.feed_base_url = value
        feed_url appcast.feed_url
      when :feed_filename
        appcast.feed_filename = value
        feed_url appcast.feed_url
      when :version
        version value
      when :notes_base_url, :package_base_url, :notes_filename, :package_filename
        appcast.send "#{key}=", value
      else
        raise "Unknown Sparkle config option #{key}"
      end
    end
    alias_method :release, :publish

    def version(vstring)
      @config.version = vstring.to_s
      @config.short_version = vstring.to_s
    end

    def version_string
      "#{@config.version} (#{@config.short_version})"
    end

    def feed_url(url)
      @config.info_plist['SUFeedURL'] = url
    end

    def public_key(path_in_resources_folder)
      @config.info_plist['SUPublicDSAKeyFile'] = path_in_resources_folder
    end

    # File manipulation and certificates

    def add_to_gitignore
      @ignorable = ['sparkle/release','sparkle/release/*','sparkle/config/dsa_priv.pem']
      return unless File.exist?(gitignore_path)
      File.open(gitignore_path, 'r') do |f|
        f.each_line do |line|
          @ignorable.delete(line) if @ignorable.include?(line)
        end
      end
      File.open(gitignore_path, 'a') do |f|
        @ignorable.each do |i|
          f << "#{i}\n"
        end
      end if @ignorable.any?
      `cat #{gitignore_path}`
    end

    def create_sparkle_folder
      create_config_folder
      create_release_folder
    end

    def create_config_folder
      FileUtils.mkdir_p(sparkle_config_path) unless File.exist?(sparkle_config_path)
    end

    def create_release_folder
      FileUtils.mkdir_p(sparkle_release_path) unless File.exist?(sparkle_release_path)
    end

    def generate_keys
      return false unless config_ok?
      create_config_folder

      [dsa_param_path, private_key_path, public_key_path].each do |file|
        if File.exist? file
          App.info "Sparkle", "Error: file exists.
There's already a '#{file}'. Be careful not to override or lose your certificates. \n
Delete this file if you're sure. \n
Aborting (no action performed)
          "
          return
        end
      end
      `#{openssl} dsaparam 1024 < /dev/urandom > #{dsa_param_path}`
      `#{openssl} gendsa #{dsa_param_path} -out #{private_key_path}`
      generate_public_key
      `rm #{dsa_param_path}`
      App.info "Sparkle", "Generated private and public certificates.
Details:
  *  Private certificate: ./#{private_key_path}
  *  Public certificate: ./#{public_key_path}
Warning:
ADD YOUR PRIVATE CERTIFICATE TO YOUR `.gitignore` OR EQUIVALENT AND BACK IT UP!
KEEP IT PRIVATE AND SAFE!
If you lose it, your users will be unable to upgrade.
      "
    end

    def generate_public_key
      FileUtils.mkdir_p('resources') unless File.exist?('resources')
      `#{openssl} dsa -in #{private_key_path} -pubout -out #{public_key_path}`
    end

    # A few helpers

    def openssl
      "/usr/bin/openssl"
    end

    def project_path
      @project_path ||= Pathname.new(@config.project_dir)
    end

    def vendor_path
      @vendor_path ||= Pathname.new(project_path + 'vendor/')
    end

    def gitignore_path
      project_path + ".gitignore"
    end

    def sparkle_release_path
      project_path + RELEASE_PATH
    end

    def sparkle_config_path
      project_path + CONFIG_PATH
    end

    def dsa_param_path
      sparkle_config_path + "dsaparam.pem"
    end

    def private_key_path
      sparkle_config_path + "dsa_priv.pem"
    end

    def public_key_path
      pub_key_file = @config.info_plist['SUPublicDSAKeyFile']
      project_path + "resources/#{pub_key_file}"
    end

    def app_bundle_path
      Pathname.new @config.app_bundle_raw('MacOSX')
    end

    def app_release_path
      app_bundle_path.parent.to_s
    end

    def app_name
      File.basename(app_bundle_path, '.app')
    end

    def zip_file
      appcast.package_filename || "#{app_name}.zip"
    end

    def app_file
      "#{app_name}.app"
    end

  end
end
