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
            o.banner = "Usage: vagrant plugin update [names...] [-h]"
            o.separator ""

            o.on("--local", "Update plugin in local project") do |l|
              options[:env_local] = l
            end
          end

          # Parse the options
          argv = parse_options(opts)
          return if !argv

          # Update the gem
          action(Action.action_update, {
            plugin_name:        argv,
            env_local:          options[:env_local]
          })

          # Success, exit status 0
          0
        end
      end
    end
  end
end
