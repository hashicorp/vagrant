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

	# Set a max fork limit
        fork_limit = 2

        # Set a default sleep time
        sleep_time = 30

        # Create an hash to hold the pids of a fork.
        pids = {}

        # Go over each VM and bring it up
        @logger.debug("'Up' each target VM...")
        with_target_vms(argv) do |vm|
          # Check if we have already forked to out limit.
          if pids.size >= fork_limit
              @logger.warn("Max fork limit waiting for a process to complete")
              pid = Process.wait()
              @logger.debug("Pid #{pid.to_s} completed")
              pids.delete(pid)
          end 
          pid = fork do
            if vm.created?
              @logger.info("Booting: #{vm.name}")
              vm.ui.info I18n.t("vagrant.commands.up.vm_created")
              vm.start(options)
            else
              @logger.info("Creating: #{vm.name}")
              vm.up(options)
            end
          end
          @logger.debug("Fork #{pid.to_s} created")
          pids[pid] = 1
          sleep(sleep_time)
        end

        pids.keys.each do | pid |
          @logger.debug("All forks created waiting for pid #{pid.to_s} to complete")
          Process.waitpid(pid) 
        end

        # Success, exit status 0
        0
       end
    end
  end
end
