module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class ReadSMBShareIds
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant::action::vm::smb")
        end

        def call(env)
          cache_file = env[:machine].data_dir.join("smb_share_ids")
          if cache_file.file?
            env[:smb_machine_action] = env[:machine_action]
            env[:smb_share_ids]      = File.read(cache_file).split
          end
          @app.call(env)
        end
      end
    end
  end
end
