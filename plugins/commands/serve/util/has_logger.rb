module VagrantPlugins
  module CommandServe
    module Util
      # Creates a new logger instance and provides method
      # to access it
      module HasLogger
        def logger
          @logger
        end

        def initialize(*args, **opts, &block)
          @logger = Log4r::Logger.new(self.class.name.downcase)

          sup = self.method(:initialize).super_method
          if sup.parameters.empty?
            super()
          elsif !opts.empty? && sup.parameters.detect{ |type, _| type == :keyreq || type == :keyrest }
            super
          else
            super(*args, &block)
          end
        end
      end
    end
  end
end
