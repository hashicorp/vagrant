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
            result = nil
            attempts = 0
            while attempts < 5 && result.nil?
              attempts += 1
              result = @env.ui.ask(
                I18n.t("vagrant.commands.plugin.expunge_request_reinstall") +
                  " [N]: "
              )
              result = result.to_s.downcase.strip
              result = "n" if result.empty?
              if !["y", "yes", "n", "no"].include?(result)
                result = nil
                @env.ui.error("Please answer Y or N")
              else
                result = result[0,1]
              end
            end
            options[:reinstall] = result == "y"
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
