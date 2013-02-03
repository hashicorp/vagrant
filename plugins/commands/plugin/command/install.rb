require 'optparse'

module VagrantPlugins
  module CommandPlugin
    module Command
      class Install < Vagrant.plugin("2", :command)
        def execute
          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant plugin install <name> [-h]"
          end

          # Parse the options
          argv = parse_options(opts)
          return if !argv
          raise Vagrant::Errors::CLIInvalidUsage, :help => opts.help.chomp if argv.length < 1

          # Install the gem
          @env.action_runner.run(Action.action_install, {
            :gem_helper => GemHelper.new(@env.gems_path),
            :plugin_name => argv[0],
            :plugin_state_file => StateFile.new(@env.data_dir.join("plugins.json"))
          })

          # Success, exit status 0
          0
        end
      end
    end
  end
end
