# coding: utf-8
require 'optparse'

module VagrantPlugins
  module CommandSnapshot
    module Command
      # This is the subcommand `vagrant snapshot delete` which will remove a
      # snapshot from a virtual machine using the provider's action.
      class Delete < Vagrant.plugin('2', :command)
        def self.synopsis
          'Destroy snapshots form the command-line interface'
        end
        
        def execute
          options = { }
          opts = OptionParser.new do |o|
            o.banner = 'Usage: vagrant snapshot delete <machine> <snapshot> [<options>]'
            o.on('-f', '--force', 'Forcefully destroy snapshot without confirmation') do 
              options[:force_destroy] = true
            end
          end

          # Parse the options and require snapshot identifier.
          argv = parse_options(opts)
          return unless argv
          fail Vagrant::Errors::CLIInvalidUsage, :help => opts.help.chomp if argv.length < 2

          options[:snapshot_name] = argv[1]

          with_target_vms(argv[0], single_target: true) do |m|
            @env.action_runner.run(Action::DeleteSnapshot, {
              :action_name => "machine_action_delete_snapshot".to_sym,
              :machine => m,
              :snapshot_name => options[:snapshot_name]
            })
          end
        end
      end
    end
  end
end



