# coding: utf-8
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
          opts = OptionParser.new do |o|
            o.banner = 'Usage: vagrant snapshot restore <machine> <snapshot> [<args>]'
          end

          # Parse the options and require snapshot identifier.
          argv = parse_options(opts)
          return unless argv

          with_target_vms(argv) do |m|
            m.action(:restore_snapshot, opts)
          end
        end
      end
    end
  end
end



