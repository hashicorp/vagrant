require "log4r"

module VagrantPlugins
  module HyperV
    module Action
      class SetName
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant::hyperv::set_name")
        end

        def call(env)
          name = env[:machine].provider_config.vmname

          # If we already set the name before, then don't do anything
          sentinel = env[:machine].data_dir.join("action_set_name")
          if !name && sentinel.file?
            @logger.info("Default name was already set before, not doing it again.")
            return @app.call(env)
          end

          # If no name was manually set, then use a default
          if !name
            prefix = "#{env[:root_path].basename.to_s}_#{env[:machine].name}"
            prefix.gsub!(/[^-a-z0-9_]/i, "")

            # milliseconds + random number suffix to allow for simultaneous
            # `vagrant up` of the same box in different dirs
            name = prefix + "_#{(Time.now.to_f * 1000.0).to_i}_#{rand(100000)}"
          end

          env[:machine].provider.driver.set_name(name)

          # Create the sentinel
          sentinel.open("w") do |f|
            f.write(Time.now.to_i.to_s)
          end
          @app.call(env)
        end
      end
    end
  end
end
