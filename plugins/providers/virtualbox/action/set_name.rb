require "log4r"

module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class SetName
        def initialize(app, env)
          @logger = Log4r::Logger.new("vagrant::action::vm::setname")
          @app = app
        end

        def call(env)
          name = env[:machine].provider_config.name

          # If no name was manually set, then use a default
          if !name
            prefix = env[:root_path].basename.to_s
            prefix.gsub!(/[^-a-z0-9_]/i, "")
            name = prefix + "_#{Time.now.to_i}"
          end

          @logger.info("Setting the name of the VM: #{name}")
          env[:machine].provider.driver.set_name(name)

          @app.call(env)
        end
      end
    end
  end
end
