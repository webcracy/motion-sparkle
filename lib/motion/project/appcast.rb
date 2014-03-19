module Motion::Project
  class Sparkle

    def create_release_notes
      if File.exist?(release_notes_template_path)
        File.open("#{release_notes_path}", "w") do |f|
          template = File.read(release_notes_template_path)
          f << ERB.new(template).result(binding)
        end
        App.info 'Create', "./#{release_notes_path}"
      else
        App.fail "Release notes template not found as expected at ./#{release_notes_template_path}"
      end
    end

    def create_appcast
      appcast_file = File.open("#{sparkle_release_path}/#{appcast.feed_filename}", 'w') do |f|
        xml_string = ''
        doc = REXML::Formatters::Pretty.new
        doc.write(appcast_xml, xml_string)
        f << "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
        f << xml_string
        f << "\n"
      end
      if appcast_file
        App.info "Create", "./#{sparkle_release_path}/#{appcast.feed_filename}"
      else
        App.info "Fail", "./#{sparkle_release_path}/#{appcast.feed_filename} not created"
      end
    end

    def appcast_xml
      base_url = appcast.base_url
      package_url = if appcast.package_url.nil?
        base_url
      else
        File.join(appcast.package_url, @config.version)
      end

      rss = REXML::Element.new 'rss'
      rss.attributes['xmlns:atom'] = "http://www.w3.org/2005/Atom"
      rss.attributes['xmlns:sparkle'] = "http://www.andymatuschak.org/xml-namespaces/sparkle"
      rss.attributes['xmlns:version'] = "2.0"
      rss.attributes['xmlns:dc'] = "http://purl.org/dc/elements/1.1/"
      channel = rss.add_element 'channel'
      channel.add_element('title').text = @config.name
      channel.add_element('description').text = "#{@config.name} updates"
      channel.add_element('link').text = @config.info_plist["SUFeedURL"]
      channel.add_element('language').text = 'en'
      channel.add_element('pubDate').text = Time.now.strftime("%a, %d %b %Y %H:%M:%S %z")
      atom_link = channel.add_element('atom:link')
      atom_link.attributes['href'] = @config.info_plist["SUFeedURL"]
      atom_link.attributes['rel'] = 'self'
      atom_link.attributes['type'] = "application/rss+xml"
      item = channel.add_element 'item'
      item.add_element('title').text = "#{@config.name} #{@config.version}"
      item.add_element('pubDate').text = Time.now.strftime("%a, %d %b %Y %H:%M:%S %z")
      guid = item.add_element('guid')
      guid.text = "#{@config.name}-#{@config.version}"
      guid.attributes['isPermaLink'] = false
      item.add_element('sparkle:releaseNotesLink').text = "#{base_url}/#{appcast.notes_filename}"
      enclosure = item.add_element('enclosure')
      enclosure.attributes['url'] = "#{package_url}/#{@package_file}"
      enclosure.attributes['length'] = "#{@package_size}"
      enclosure.attributes['type'] = "application/octet-stream"
      enclosure.attributes['sparkle:version'] = @config.version
      enclosure.attributes['sparkle:dsaSignature'] = @package_signature
      rss
    end

    def release_notes_template_path
      sparkle_config_path + "release_notes.template.erb"
    end

    def release_notes_content_path
      sparkle_config_path + "release_notes.content.html"
    end

    def release_notes_path
      sparkle_release_path + appcast.notes_filename.to_s
    end

    def release_notes_content
      if File.exist?(release_notes_content_path)
        File.read(release_notes_content_path)
      else
        App.fail "Missing #{release_notes_content_path}"
      end
    end

    def release_notes_html
      release_notes_content
    end


    class Appcast
      attr_accessor :base_url, :feed_filename, :notes_filename, :package_filename, :package_url

      def initialize
        @feed_filename = 'releases.xml'
        @notes_filename = 'release_notes.html'
        @package_filename = nil
        @package_url = nil
        @base_url = nil
      end

      def full_feed_url
        "#{base_url}/#{feed_filename}"
      end
    end

  end
end
