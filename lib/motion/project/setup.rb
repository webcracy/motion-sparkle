module Motion::Project
  class Sparkle
    def setup_ok?
      config_ok?
      certificates_ok?
    end

    def config_ok?
      check_base_url
      check_feed_url
      check_public_key
    end

    def check_base_url
      return true if appcast.base_url.present?

      App.fail "Sparkle :base_url missing. Use `release :base_url, 'http://example.com/your_app_folder'` in your Rakefile's `app.sparkle` block"
    end

    def check_feed_url
      return true if feed_url.present? && appcast.feed_filename.present?

      App.fail 'Sparkle :feed_filename is nil or blank. Please check your Rakefile.'
    end

    def check_public_key
      return true if public_EdDSA_key.present?

      App.fail 'Sparkle :public_key is nil or blank. Please check your Rakefile.'
    end

    def certificates_ok?(silence = false)
      unless File.exist?("./#{Sparkle::CONFIG_PATH}")
        return false if silence

        App.fail "Missing `#{Sparkle::CONFIG_PATH}`. Run `rake sparkle:setup` to get started"
      end

      if appcast.use_exported_private_key
        unless File.exist?(private_key_path)
          return false if silence

          App.fail "Missing `#{private_key_path}`. Please run `rake sparkle:setup_certificates` or check the docs to know where to put them."
        end
      end

      unless public_EdDSA_key.present?
        return false if silence

        App.fail "Missing `#{public_key_path}`. Did you configure `release :public_key` correctly in the Rakefile? Advanced: recreate your public key with `rake sparkle:recreate_public_key`"
      end

      true
    end

    def setup
      verify_installation
      create_sparkle_folder
      add_to_gitignore
      copy_templates

      return false unless config_ok?
      App.info 'Sparkle', 'Config found'

      silence = true
      unless certificates_ok?(silence)
        App.info 'Sparkle', <<~CERTIFICATES
          Certificates not found

                      Please generate your private and public keys with
                         `rake sparkle:setup_certificates`

                      If you already have your certificates and only need to include them in the project, follow these steps:
                         1. Rename your private key to `./#{private_key_path}`
                            and make sure you've added it to your `.gitignore` file - it should NEVER be
                            stored in your repository
                         2. Add `publish :public_key, 'PUBLIC_KEY'` to the Sparkle config in your Rakefile
        CERTIFICATES

       return false
      end

      App.info 'Sparkle', 'Certificates found'
      App.info 'Sparkle', 'Setup OK. After `rake build:release`, you can now run `rake sparkle:package`.'
    end
  end
end
