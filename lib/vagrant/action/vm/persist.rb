module Vagrant
  class Action
    module VM
      class Persist
        def initialize(app, env)
          @app = app

          # Error the environment if the dotfile is not valid
          env.error!(:dotfile_error, :env => env.env) if File.exist?(env.env.dotfile_path) &&
                                                         !File.file?(env.env.dotfile_path)
        end

        def call(env)
          env.logger.info "Persisting the VM UUID (#{env["vm"].uuid})"
          env.env.update_dotfile

          @app.call(env)
        end
      end
    end
  end
end
