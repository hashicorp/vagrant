require "log4r"

module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class DefaultName
        def initialize(app, env)
          @logger = Log4r::Logger.new("vagrant::action::vm::defaultname")
          @app = app
        end

        def call(env)
          # Figure out the name and sanitize the default
          prefix = env[:root_path].basename.to_s
          prefix.gsub!(/[^-a-z0-9_]/i, "")
          name = prefix + "_#{Time.now.to_i}"
          @logger.info("Setting the default name of the VM: #{name}")

          env[:machine].provider.driver.set_name(name)

          @app.call(env)
        end
      end
    end
  end
end
