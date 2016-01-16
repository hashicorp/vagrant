require 'json'
require 'optparse'

require 'vagrant'

require Vagrant.source_root.join("plugins/commands/up/start_mixins")

require_relative "push_shared"

module VagrantPlugins
  module CommandSnapshot
    module Command
      class Pop < Vagrant.plugin("2", :command)
        include PushShared
        include VagrantPlugins::CommandUp::StartMixins

        def execute
          options = {}
          options[:snapshot_delete] = true
          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant snapshot pop [options] [vm-name]"
            o.separator ""
            build_start_options(o, options)
            o.separator "Restore state that was pushed with `vagrant snapshot push`."

            o.on("--no-delete", "Don't delete the snapshot after the restore") do
                options[:snapshot_delete] = false
            end
          end

          # Parse the options
          argv = parse_options(opts)
          return if !argv

          # Validate the provisioners
          validate_provisioner_flags!(options, argv)

          return shared_exec(argv, method(:pop), options)
        end
      end
    end
  end
end
