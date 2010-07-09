module Vagrant
  class Action
    module VM
      class ClearSharedFolders
        def initialize(app, env)
          @app = app
          @env = env
        end

        def call(env)
          @env = env

          clear_shared_folders
          @app.call(env)
        end

        def clear_shared_folders
          if @env["vm"].vm.shared_folders.length > 0
            @env.logger.info "Clearing previously set shared folders..."

            folders = @env["vm"].vm.shared_folders.dup
            folders.each do |shared_folder|
              shared_folder.destroy
            end

            @env["vm"].reload!
          end
        end
      end
    end
  end
end
