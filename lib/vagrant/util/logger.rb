require "log4r"

module Vagrant
  module Util
    # Adds a logger method which provides automatically
    # namespaced logger instance
    module Logger

      # @return [Log4r::Logger]
      def logger
        if !@_logger
          name = (self.is_a?(Module) ? self : self.class).name.downcase
          if !name.start_with?("vagrant")
            name = "vagrant::root::#{name}"
          end
          @_logger = Log4r::Logger.new(name)
        end
        @_logger
      end
    end
  end
end
