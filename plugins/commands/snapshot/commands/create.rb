# coding: utf-8
module VagrantPlugins
  module CommandSnapshot
    module Command
      class Create < Vagrant.plugin(2, :command)
        def self.synopsis
          'Create snapshots from the command-line interface'
        end

        def execute
          opts = OptionParser.new do |o|
            o.banner 'vagrant snapshot take <machine> <name> [<options>]'

            o.on('--live', 'Perform the snapshot without stopping guest') do |optarg|
              opts[:live_snapshot] = true
            end

            o.on('--description', 'Describe this snapshot') do |optarg|
              opts[:description] = optarg
            end
          end

          # Parse the options and get the virtual machine.
          argv = parse_options(opts)
          return unless argv

          with_target_vms(argv) do |m|
            m.action(:create_snapshot, opts)
          end
        end

      end
    end
  end
end
