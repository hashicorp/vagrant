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
        
        # set up array to hold pids of forks
        pids = [];

    
        # Go over each VM and bring it up
        @logger.debug("'Up' each target VM...")
        with_target_vms(argv) do |vm|
          if vm.created?
            @logger.info("Booting: #{vm.name}")
            vm.ui.info I18n.t("vagrant.commands.up.vm_created")
            vm.start(options)
          else
            @logger.info("Creating: #{vm.name}")
            r = vm.up(options)
            pids.push(r)

          end
        end

        # if we have pids wait for them.
        pids.each do | pid |
          @logger.info("Waiting for pid #{pid.to_s} to complete")
          Process.waitpid(pid) 
        end

        # Success, exit status 0
        0
       end
    end
  end
end
