# frozen_string_literal: true

require 'erb'
require 'rexml/document'

module Motion
  module Project
    class Sparkle
      TEMPLATE_PATHS = [
        File.expand_path(File.join(__FILE__, '../appcast'))
      ].freeze

      def all_templates
        @all_templates ||= begin
          templates = {}
          TEMPLATE_PATHS.map { |path| Dir.glob("#{path}/*") }.flatten.each do |template_path|
            templates[File.basename(template_path)] = template_path
          end
          templates
        end
      end

      def copy_templates(force = false)
        all_templates.each_pair do |tmpl, path|
          result = "#{sparkle_config_path}/#{tmpl}"
          if File.exist?(result) && !force
            App.info 'Exists', result
          else
            FileUtils.cp(path, "#{sparkle_config_path}/")
            App.info 'Create', "./#{sparkle_config_path}/#{tmpl}"
          end
        end
      end
    end
  end
end
