require 'optparse'

module VagrantPlugins
  module CommandSnapshot
    module Command
      class Restore < Vagrant.plugin("2", :command)
        def execute
          options = {}

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant snapshot restore [options] [vm-name] <name>"
            o.separator ""
            o.separator "Restore a snapshot taken previously with snapshot save."
          end

          # Parse the options
          argv = parse_options(opts)
          return if !argv
          if argv.empty? || argv.length > 2
            raise Vagrant::Errors::CLIInvalidUsage,
              help: opts.help.chomp
          end

          name = argv.pop
          with_target_vms(argv) do |vm|
            vm.action(:snapshot_restore, snapshot_name: name)
          end

          # Success, exit status 0
          0
        end
      end
    end
  end
end
