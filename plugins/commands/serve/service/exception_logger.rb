module VagrantPlugins
  module CommandServe
    module Service
      module ExceptionLogger

        LOGGER = Log4r::Logger.new("vagrant::plugin::command::serve::service")

        def self.log_exception(method_name)
          define_method method_name do |*arguments|
            begin
              super(*arguments)
            rescue => err
              LOGGER.debug(err.message)
              LOGGER.debug(err.backtrace.join("\n"))
              raise err
            end
          end
        end
      end
    end
  end
end
