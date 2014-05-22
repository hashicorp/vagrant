require 'optparse'

require "vagrant"

require Vagrant.source_root.join("plugins/commands/up/start_mixins")

module VagrantPlugins
  module CommandRebuild
    class Command < Vagrant.plugin("2", :command)
      # We assume that the `up` and `destroy` plugin exists and that we'll have access
      # to this.

      def self.synopsis
        "rebuild vagrant machine"
      end

      def execute
        options = {}
        options[:provision_ignore_sentinel] = false

        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant rebuild"
          o.separator ""
        end

        # Parse the options
        argv = parse_options(opts)
        return if !argv

        @logger.debug("'rebuild' VM...")
        with_target_vms(argv) do |vm|
           vm.action(
            :destroy, :force_confirm_destroy => true)

          vm.action(:up)
        end

        # Success, exit status 0
        0
      end
    end
  end
end
