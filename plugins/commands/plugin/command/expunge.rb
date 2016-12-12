require 'optparse'

require_relative "base"

module VagrantPlugins
  module CommandPlugin
    module Command
      class Expunge < Base
        def execute
          options = {}

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant plugin expunge [-h]"

            o.on("--force", "Do not prompt for confirmation") do |force|
              options[:force] = force
            end

            o.on("--reinstall", "Reinstall current plugins after expunge") do |reinstall|
              options[:reinstall] = reinstall
            end
          end

          # Parse the options
          argv = parse_options(opts)
          return if !argv
          raise Vagrant::Errors::CLIInvalidUsage, help: opts.help.chomp if argv.length > 0

          plugins = Vagrant::Plugin::Manager.instance.installed_plugins

          if !options[:reinstall] && !options[:force] && !plugins.empty?
            result = @env.ui.ask(
              I18n.t("vagrant.commands.plugin.expunge_request_reinstall") +
                " [Y/N]:"
            )
            options[:reinstall] = result.to_s.downcase.strip == "y"
          end

          # Remove all installed user plugins
          action(Action.action_expunge, options)

          if options[:reinstall]
            @env.ui.info(I18n.t("vagrant.commands.plugin.expunge_reinstall"))
            plugins.each do |plugin_name, plugin_info|
              next if plugin_info["system"] # system plugins do not require re-install
              # Rebuild information hash to use symbols
              plugin_info = Hash[
                plugin_info.map do |key, value|
                  ["plugin_#{key}".to_sym, value]
                end
              ]
              action(
                Action.action_install,
                plugin_info.merge(
                  plugin_name: plugin_name
                )
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
