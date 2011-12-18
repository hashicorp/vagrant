require 'optparse'

module Vagrant
  module Command
    class SSH < Base
      def execute
        options = {}

        opts = OptionParser.new do |opts|
          opts.banner = "Usage: vagrant ssh [vm-name] [-c command]"

          opts.separator ""

          opts.on("-c", "--command COMMAND", "Execute an SSH command directly.") do |c|
            options[:command] = c
          end
        end

        argv = parse_options(opts)
        return if !argv

        # SSH always requires a target VM
        raise Errors::MultiVMTargetRequired, :command => "ssh" if @env.multivm? && !argv[0]

        # Execute the actual SSH
        with_target_vms(argv[0]) do |vm|
          # Basic checks that are required for proper SSH
          raise Errors::VMNotCreatedError if !vm.created?
          raise Errors::VMInaccessible if !vm.vm.accessible?
          raise Errors::VMNotRunningError if !vm.vm.running?

          if options[:command]
            ssh_execute(vm, options[:command])
          else
            ssh_connect(vm)
          end
        end
      end

      protected

      def ssh_execute(vm, command=nil)
        @logger.debug("Executing command: #{command}")
        vm.ssh.execute do |ssh|
          ssh.exec!(command) do |channel, type, data|
            if type != :exit_status
              # Print the SSH output as it comes in, but don't prefix it and don't
              # force a new line so that the output is properly preserved
              vm.ui.info(data.to_s, :prefix => false, :new_line => false)
            end
          end
        end
      end

      def ssh_connect(vm)
        @logger.debug("`exec` into ssh prompt")
        vm.ssh.connect
      end
    end
  end
end
