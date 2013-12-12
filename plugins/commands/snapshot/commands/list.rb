# coding: utf-8
module VagrantPlugins
  module CommandSnapshot
    module Command
      # This is the subcommand for the `vagrant snapshot` which lists
      # all of the snapshots for each virtual machine in this project.
      class List < Vagrant.plugin('2', :command)
        def self.synopsis
          'List all snapshots from the command-line interface'
        end
        
        def execute
          opts = OptionParser.new do |o|
            o.banner = 'Usage: vagrant snapshot list <machine> [<machines>]'
          end

          # Parse the options for machine filters.
          argv = parse_options(opts)
          return unless argv
          
          # Reduce the set of virtual machines. 
          with_target_vms(argv) do |m|
            m.action(:list_snapshots, {})
          end
        end
      end
    end
  end
end
