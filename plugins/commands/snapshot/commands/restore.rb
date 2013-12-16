# coding: utf-8
require 'optparse'

module VagrantPlugins
  module CommandSnapshot
    module Command
      # This is the subcommand `vagrant snapshot restore` which will restore
      # a guest machine to a previous snapshot.
      class Restore < Vagrant.plugin('2', :command)
        def self.synopsis
          'Restore a guest to a previous snapshot in time.'
        end
        
        def execute
          options = {}
          opts = OptionParser.new do |o|
            o.banner = 'Usage: vagrant snapshot restore <machine> <snapshot> [<args>]'
          end

          # Parse the options and require snapshot identifier.
          argv = parse_options(opts)
          return unless argv
          fail Vagrant::Errors::CLIInvalidUsage, :help => opts.help.chomp if argv.length < 2

          options[:snapshot_name] = argv[1]
          with_target_vms(argv[0], single_target: true) do |m|
            @env.action_runner.run(Action::RestoreSnapshot, {
              :action_name => "machine_action_restore_snapshot".to_sym,
              :machine => m,
              :snapshot_name => options[:snapshot_name]
            })            
          end
        end
      end
    end
  end
end



