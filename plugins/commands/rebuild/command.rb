require 'optparse'

require "vagrant"


module VagrantPlugins
  module CommandRebuild
    class Command < Vagrant.plugin("2", :command)

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
