require 'optparse'

require_relative "base"
require_relative "mixin_install_opts"

module VagrantPlugins
  module CommandPlugin
    module Command
      class Update < Base
        include MixinInstallOpts

        def execute
          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant plugin update [names...] [-h]"
            o.separator ""
          end

          # Parse the options
          argv = parse_options(opts)
          return if !argv

          # Update the gem
          action(Action.action_update, {
            plugin_name:        argv,
          })

          # Success, exit status 0
          0
        end
      end
    end
  end
end
