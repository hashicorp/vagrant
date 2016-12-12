require 'optparse'

require Vagrant.source_root.join("plugins/commands/up/start_mixins")

module VagrantPlugins
  module CommandResume
    class Command < Vagrant.plugin("2", :command)
      # We assume that the `up` plugin exists and that we'll have access
      # to this.
      include VagrantPlugins::CommandUp::StartMixins

      def self.synopsis
        "resume a suspended vagrant machine"
      end

      def execute
        options = {}
        options[:provision_ignore_sentinel] = false

        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant resume [vm-name]"
          o.separator ""
          build_start_options(o, options)
        end

        # Parse the options
        argv = parse_options(opts)
        return if !argv

        # Validate the provisioners
        validate_provisioner_flags!(options, argv)

        @logger.debug("'resume' each target VM...")
        with_target_vms(argv) do |machine|
          machine.action(:resume, options)
        end

        # Success, exit status 0
        0
      end
    end
  end
end
