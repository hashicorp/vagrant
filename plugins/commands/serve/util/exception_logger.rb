module VagrantPlugins
  module CommandServe
    module Util
      # Adds exception logging to all public instance methods
      module ExceptionLogger
        def self.prepended(klass)
          klass.public_instance_methods(false).each do |m_name|
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
