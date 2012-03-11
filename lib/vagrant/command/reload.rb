require 'optparse'

require 'vagrant/command/start_mixins'

module Vagrant
  module Command
    class Reload < Base
      include StartMixins

      def execute
        options = {}

          opts = OptionParser.new do |opts|
          opts.banner = "Usage: vagrant reload [vm-name]"
          opts.separator ""
          build_start_options(opts, options)
        end

        # Parse the options
        argv = parse_options(opts)
        return if !argv

        @logger.debug("'reload' each target VM...")
        with_target_vms(argv) do |vm|
          if vm.created?
            @logger.info("Reloading: #{vm.name}")
            vm.reload(options)
          else
            @logger.info("Not created: #{vm.name}. Not reloading.")
            vm.ui.info I18n.t("vagrant.commands.common.vm_not_created")
          end
        end

        # Success, exit status 0
        0
       end
    end
  end
end
