# coding: utf-8
require 'optparse'

module VagrantPlugins
  module CommandSnapshot
    module Command
      # This is the subcommand for the `vagrant snapshot` which lists
      # all of the snapshots for each virtual machine in this project.
      class List < Vagrant.plugin('2', :command)
        def self.synopsis
          'lists snapshots'
        end
        
        def execute
          options = {}
          opts = OptionParser.new do |o|
            o.banner = 'Usage: vagrant snapshot list [<machines>]'
            o.on('-m', '--machinereadable', 'Output in a machinereadable format') do 
              options[:machine_readable] = true
            end
            o.on('-v', '--verbose', 'Output detailed, verbose information') do
              options[:details] = true
            end
          end

          # Parse the options for machine filters.
          argv = parse_options(opts)
          return unless argv
          
          # Reduce the set of virtual machines. 
          with_target_vms(argv) do |m|
            @env.action_runner.run(Action::ListSnapshots, {
              :action_name => "machine_action_list_snapshots".to_sym,
              :machine => m,
              :snapshot_machinereadable => options[:machine_readable],
              :snapshot_details => options[:details]
            })
          end
        end
      end
    end
  end
end
