require 'optparse'

require 'vagrant/command/start_mixins'

module Vagrant
  module Command
    class Up < Base
      include StartMixins

      def execute
        options = {}
        opts = OptionParser.new do |opts|
          opts.banner = "Usage: vagrant up [vm-name] [--[no-]provision] [-h]"
          opts.separator ""
          build_start_options(opts, options)
        end

        # Parse the options
        argv = parse_options(opts)
        return if !argv

        # Go over each VM and bring it up
        @logger.debug("'Up' each target VM...")
        with_target_vms(argv) do |vm|
          if vm.created?
            @logger.info("Booting: #{vm.name}")
            vm.ui.info I18n.t("vagrant.commands.up.vm_created")
            vm.start(options)
          else
            @logger.info("Creating: #{vm.name}")
            vm.up(options)
          end
        end
      end
    end
  end
end
