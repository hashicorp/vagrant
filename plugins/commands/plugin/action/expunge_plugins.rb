require "vagrant/plugin/manager"

module VagrantPlugins
  module CommandPlugin
    module Action
      # This middleware removes user installed plugins by
      # removing:
      #   * ~/.vagrant.d/plugins.json
      #   * ~/.vagrant.d/gems
      # Usage should be restricted to when a repair is
      # unsuccessful and the only reasonable option remaining
      # is to re-install all plugins
      class ExpungePlugins
        def initialize(app, env)
          @app = app
        end

        def call(env)
          if !env[:force]

            result = nil
            attempts = 0
            while attempts < 5 && result.nil?
              attempts += 1
              result = env[:ui].ask(
                I18n.t("vagrant.commands.plugin.expunge_confirm") +
                  " [N]: "
              )
              result = result.to_s.downcase.strip
              result = "n" if result.empty?
              if !["y", "yes", "n", "no"].include?(result)
                result = nil
                env[:ui].error("Please answer Y or N")
              else
                result = result[0,1]
              end
            end

            if result != 'y'
              abort_action = true
            end
          end

          if !abort_action
            files = []
            dirs = []

            # Do not include global paths if local only
            if !env[:env_local_only] || env[:global_only]
              files << Vagrant::Plugin::Manager.instance.user_file.path
              dirs << Vagrant::Bundler.instance.plugin_gem_path
            end

            # Add local paths if they exist
            if Vagrant::Plugin::Manager.instance.local_file && (env[:env_local_only] || !env[:global_only])
              files << Vagrant::Plugin::Manager.instance.local_file.path
              dirs << Vagrant::Bundler.instance.env_plugin_gem_path
            end

            # Expunge files and directories
            files.find_all(&:exist?).map(&:delete)
            dirs.find_all(&:exist?).map(&:rmtree)

            env[:ui].info(I18n.t("vagrant.commands.plugin.expunge_complete"))

            @app.call(env)
          else
            env[:ui].info(I18n.t("vagrant.commands.plugin.expunge_aborted"))
          end
        end
      end
    end
  end
end
