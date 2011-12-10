module Vagrant
  module Action
    module VM
      class ClearSharedFolders
        def initialize(app, env)
          @app = app
          @env = env
        end

        def call(env)
          proc = lambda do |vm|
            if vm.shared_folders.length > 0
              env[:ui].info I18n.t("vagrant.actions.vm.clear_shared_folders.deleting")

              vm.shared_folders.dup.each do |shared_folder|
                shared_folder.destroy
              end
            end
          end

          env["vm.modify"].call(proc)
          @app.call(env)
        end
      end
    end
  end
end
