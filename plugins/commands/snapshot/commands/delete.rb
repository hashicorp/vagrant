# coding: utf-8
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
          opts = OptionParser.new do |o|
            o.banner = 'Usage: vagrant snapshot delete <machine> <snapshot> [<args>]'
            o.on('--force', 'Forcefully destroy snapshot without confirmation') do 
              opts[:force_destroy] = true
            end
          end

          # Parse the options and require snapshot identifier.
          argv = parse_options(opts)
          return unless argv

          with_target_vms(argv) do |m|
            m.action(:delete_snapshot, opts)
          end
        end
      end
    end
  end
end



