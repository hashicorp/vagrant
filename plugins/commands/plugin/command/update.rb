require 'optparse'

require_relative "base"
require_relative "mixin_install_opts"

module VagrantPlugins
  module CommandPlugin
    module Command
      class Update < Base
        include MixinInstallOpts

        def execute
          options = {}

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant plugin update <name> [-h]"
            o.separator ""
            build_install_opts(o, options)
          end

          # Parse the options
          argv = parse_options(opts)
          return if !argv
          raise Vagrant::Errors::CLIInvalidUsage, :help => opts.help.chomp if argv.length < 1

          # Update the gem
          action(Action.action_update, {
            :plugin_entry_point => options[:entry_point],
            :plugin_prerelease  => options[:plugin_prerelease],
            :plugin_version     => options[:plugin_version],
            :plugin_sources     => options[:plugin_sources],
            :plugin_name        => argv[0]
          })

          # Success, exit status 0
          0
        end
      end
    end
  end
end
