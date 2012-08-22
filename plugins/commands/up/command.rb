require 'optparse'

require "vagrant"

require File.expand_path("../start_mixins", __FILE__)

module VagrantPlugins
  module CommandUp
    class Command < Vagrant.plugin("1", :command)
      include StartMixins

      def execute
        options = {}
        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant up [vm-name] [--[no-]provision] [-h]"
          o.separator ""
          build_start_options(o, options)
        end

        # Parse the options
        argv = parse_options(opts)
        return if !argv

        # Go over each VM and bring it up
        @logger.debug("'Up' each target VM...")
        with_target_vms(argv) do |machine|
          machine.action(:up)
        end

        # Success, exit status 0
        0
      end
    end
  end
end
