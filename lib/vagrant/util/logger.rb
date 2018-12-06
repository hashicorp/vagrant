require "log4r"

module Vagrant
  module Util
    # Adds a logger method which provides automatically
    # namespaced logger instance
    module Logger

      # @return [Log4r::Logger]
      def logger
        if !@_logger
          @_logger = Log4r::Logger.new(self.class.name.downcase)
        end
        @_logger
      end
    end
  end
end
