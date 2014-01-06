require 'optparse'

require_relative "base"
require_relative "mixin_install_opts"

module VagrantPlugins
  module CommandPlugin
    module Command
      class Install < Base
        include MixinInstallOpts

        def execute
          options = {}

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant plugin install <name> [-h]"
            o.separator ""
            build_install_opts(o, options)
          end

          # Parse the options
          argv = parse_options(opts)
          return if !argv
          raise Vagrant::Errors::CLIInvalidUsage, :help => opts.help.chomp if argv.length < 1

          # Install the gems
          argv.each do |gem|
            action(Action.action_install, {
              :plugin_entry_point => options[:entry_point],
              :plugin_prerelease  => options[:plugin_prerelease],
              :plugin_version     => options[:plugin_version],
              :plugin_sources     => options[:plugin_sources],
              :plugin_name        => gem,
            })
          end

          # Success, exit status 0
          0
        end
      end
    end
  end
end
