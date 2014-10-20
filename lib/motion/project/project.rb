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
end
