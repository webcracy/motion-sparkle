module Motion::Project
  class Sparkle

    def setup_ok?
      config_ok?
      certificates_ok?
    end

    def config_ok?
      base_url_check = appcast.base_url.to_s
      if base_url_check.nil? or base_url_check.empty?
        App.fail "Sparkle :base_url missing. Use `release :base_url, 'http://example.com/your_app_folder'` in your Rakefile's `app.sparkle` block"
      end
      feed_url_check = @config.info_plist['SUFeedURL']
      feed_filename_check = appcast.feed_filename
      if feed_url_check.nil? or feed_url_check.empty? or feed_filename_check.nil? or feed_filename_check.empty?
        App.fail "Sparkle :feed_filename is nil or blank. Please check your Rakefile."
      end
      public_key_check = @config.info_plist['SUPublicDSAKeyFile'].to_s
      if public_key_check.nil? or public_key_check.empty?
        App.fail "Sparkle :public_key is nil or blank. Please check your Rakefile."
      end
      true
    end

    def certificates_ok?(silence=false)
      unless File.exist?("./#{Sparkle::CONFIG_PATH}")
        if silence
          return false
        else
          App.fail "Missing `#{Sparkle::CONFIG_PATH}`. Run `rake sparkle:setup` to get started" 
        end
      end
      unless File.exist?(private_key_path)
        if silence
          return false
        else
          App.fail "Missing `#{private_key_path}`. Please run `rake sparkle:setup_certificates` or check the docs to know where to put them."
        end
      end
      unless File.exist?(public_key_path)
        if silence
          return false
        else
          App.fail "Missing `#{public_key_path}`. Did you configure `release :public_key` correctly in the Rakefile? Advanced: recreate your public key with `rake sparkle:recreate_public_key`"
        end
      end
      true
    end

    def setup
      create_sparkle_folder
      add_to_gitignore
      copy_templates
      if config_ok?
        App.info "Sparkle", "Config found"
      else
        return false
      end

      silence = true
      if certificates_ok?(silence)
        App.info "Sparkle", "Certificates found"
      else
        App.info "Sparkle", "Certificates not found
Please generate your private and public keys with
    `rake sparkle:setup_certificates`
If you already have your certificates and only need to include them in the project, follow these steps:
    1. Rename your private key to `./#{private_key_path}`
    2. Place your public key in `./#{public_key_path}`
    3. If you wish to use a different name or location for your public key within the resources dir, 
       make sure you add `publish :public_key, 'folder/new_name.pem'` to the sparkle config in your Rakefile
        "
        return false
      end
      App.info "Sparkle", "Setup OK. After `rake build:release`, you can now run `rake sparkle:package`."
    end

  end
end