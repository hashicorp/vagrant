module VagrantPlugins
  module PluginAutoInstaller
    class ManifestChecker
      def initialize(app, env)
        @app = app
      end

      def call(env)
        env[:ui].output("Checking installed plugins")
        if env[:machine].config.auto_installer.valid?
          plugins_to_alter = env[:machine].config.auto_installer.plugin_manifest.select do |plugin, expectation|
            (Vagrant.has_plugin? plugin) != (expectation == :required)
          end
          if not plugins_to_alter.empty?
            plugins_by_state = Hash.new { |h, k| h[(k == :required) ? :install : :uninstall ] = [] }
            plugins_to_alter.each { |k, v| plugins_by_state[v] << k }
            plugins_by_state.each do |action, plugin_alter_list|
              plugin_alter_list.each do |plugin|
                env[:ui].output("#{(action == :install) ? 'Installing' : 'Removing'} plugin: #{plugin}")
                # (un)install the plugin in a separate vagrant process
                if not system "vagrant plugin #{action} #{plugin}"
                  raise Vagrant::Errors::VagrantError, message: "#{(action == :install) ? 'Installation' : 'Removal'} of plugin #{plugin} has failed. Aborting."
                end
              end
            end
            # scrap current vagrant process, and start over:
            env[:ui].output("Restarting vagrant...")
            exec("vagrant #{ARGV.join(' ')}")
            raise Vagrant::Errors::VagrantError, message: "INTERNAL ERROR: The Ruby interperter should have already exited!"
          end
        end
        @app.call(env)
      end
    end

  end
end
