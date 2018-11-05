require 'optparse'

require_relative "base"
require_relative "mixin_install_opts"

module VagrantPlugins
  module CommandPlugin
    module Command
      class Install < Base
        include MixinInstallOpts

        LOCAL_INSTALL_PAUSE = 3

        def execute
          options = { verbose: false }

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant plugin install <name>... [-h]"
            o.separator ""
            build_install_opts(o, options)

            o.on("--local", "Install plugin for local project only") do |l|
              options[:env_local] = l
            end

            o.on("--verbose", "Enable verbose output for plugin installation") do |v|
              options[:verbose] = v
            end
          end

          # Parse the options
          argv = parse_options(opts)
          return if !argv

          if argv.length < 1
            raise Vagrant::Errors::CLIInvalidUsage, help: opts.help.chomp if !options[:env_local]

            errors = @env.vagrantfile.config.vagrant.validate(nil)
            if !errors["vagrant"].empty?
              raise Errors::ConfigInvalid,
                errors: Util::TemplateRenderer.render(
                "config/validation_failed",
                errors: errors)
            end

            local_plugins = @env.vagrantfile.config.vagrant.plugins
            plugin_list = local_plugins.map do |name, info|
              "#{name} (#{info.fetch(:version, "> 0")})"
            end.join("\n")


            @env.ui.info(I18n.t("vagrant.plugins.local.install_all",
              plugins: plugin_list) + "\n")

            # Pause to allow user to cancel
            sleep(LOCAL_INSTALL_PAUSE)

            local_plugins.each do |name, info|
              action(Action.action_install,
                plugin_entry_point: info[:entry_point],
                plugin_version:     info[:version],
                plugin_sources:     info[:sources] || Vagrant::Bundler::DEFAULT_GEM_SOURCES.dup,
                plugin_name:        name,
                plugin_env_local:   true
              )
            end
          else
            # Install the gem
            argv.each do |name|
              action(Action.action_install,
                plugin_entry_point: options[:entry_point],
                plugin_version:     options[:plugin_version],
                plugin_sources:     options[:plugin_sources],
                plugin_name:        name,
                plugin_verbose:     options[:verbose],
                plugin_env_local:   options[:env_local]
              )
            end
          end

          # Success, exit status 0
          0
        end
      end
    end
  end
end
