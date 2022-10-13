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
          options[:provision_ignore_sentinel] = false
          options[:snapshot_start] = true

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant snapshot pop [options] [vm-name]"
            o.separator ""
            o.separator "Restore state that was pushed onto the snapshot stack"
            o.separator "with `vagrant snapshot push`."
            o.separator ""
            build_start_options(o, options)

            o.on("--no-delete", "Don't delete the snapshot after the restore") do
                options[:snapshot_delete] = false
            end
            o.on("--no-start", "Don't start the snapshot after the restore") do
              options[:snapshot_start] = false
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
