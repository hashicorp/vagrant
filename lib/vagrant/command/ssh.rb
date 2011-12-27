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

        # Execute the actual SSH
        with_target_vms(argv[0], true) do |vm|
          # Basic checks that are required for proper SSH
          raise Errors::VMNotCreatedError if !vm.created?
          raise Errors::VMInaccessible if !vm.state == :inaccessible
          raise Errors::VMNotRunningError if vm.state != :running

          if options[:command]
            ssh_execute(vm, options[:command])
          else
            ssh_connect(vm)
          end
        end
      end

      protected

      def ssh_execute(vm, command=nil)
        exit_status = 0

        @logger.debug("Executing command: #{command}")
        vm.ssh.execute do |ssh|
          ssh.exec!(command) do |channel, type, data|
            if type == :exit_status
              exit_status = data.to_i
            else
              # Determine the proper channel to send the output onto depending
              # on the type of data we are receiving.
              channel = type == :stdout ? :out : :error

              # Print the SSH output as it comes in, but don't prefix it and don't
              # force a new line so that the output is properly preserved
              vm.ui.info(data.to_s,
                         :prefix => false,
                         :new_line => false,
                         :channel => channel)
            end
          end
        end

        # Exit with the exit status we got from executing the command
        exit exit_status
      end

      def ssh_connect(vm)
        @logger.debug("`exec` into ssh prompt")
        vm.ssh.connect
      end
    end
  end
end
