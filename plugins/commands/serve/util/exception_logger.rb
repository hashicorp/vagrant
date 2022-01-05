module VagrantPlugins
  module CommandServe
    module Util
      # Adds exception logging to all public instance methods
      module ExceptionLogger
        def self.included(klass)
          # Get all the public instance methods. Need to search ancestors as well
          # for modules like the Guest service which includes the CapabilityPlatform
          # module
          klass_public_instance_methods = klass.public_instance_methods
          # Remove all generic instance methods from the list of ones to modify
          logged_methods = klass_public_instance_methods - Object.public_instance_methods
          logged_methods.each do |m_name|
            klass.define_method(m_name) do |*args, **opts, &block|
              begin
                super(*args, **opts, &block)
              rescue => err
                raise if !self.respond_to?(:logger)
                logger.error(err.message)
                logger.debug("#{err.class}: #{err}\n#{err.backtrace.join("\n")}")
                raise
              end
            end
          end
        end
      end
    end
  end
end
