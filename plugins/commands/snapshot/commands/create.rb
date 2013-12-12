# coding: utf-8
require 'optparse'

module VagrantPlugins
  module CommandSnapshot
    module Command
      class Create < Vagrant.plugin(2, :command)
        def self.synopsis
          'Create snapshots from the command-line interface'
        end

        def execute
          options = {}

          opts = OptionParser.new do |o|
            o.banner = 'vagrant snapshot create <machine> <name> [<options>]'
            o.on('-l', '--live', 'Perform the snapshot without stopping guest') do 
              options[:snapshot_live] = true 
            end
            o.on('--description', String, 'The snapshot description.') do |v| 
              options[:snapshot_description] = v 
            end
          end

          # Parse the options and get the virtual machine.
          argv = parse_options(opts)
          return unless argv
          fail Vagrant::Errors::CLIInvalidUsage, :help => opts.help.chomp if argv.length < 2

          options[:snapshot_name] = argv[1]

          with_target_vms(argv[0], single_target: true) do |m|
            @env.action_runner.run(Action::CreateSnapshot, {
              :action_name => "machine_action_create_snapshot".to_sym,
              :machine => m,
              :snapshot_name => options[:snapshot_name],
              :snapshot_description => options[:snapshot_description],
              :snapshot_live => options[:snapshot_live]
            })
          end
        end

      end
    end
  end
end
