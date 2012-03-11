require 'optparse'

module Vagrant
  module Command
    class SSH < Base
      def execute
        options = {}

        opts = OptionParser.new do |opts|
          opts.banner = "Usage: vagrant ssh [vm-name] [-c command] [-- extra ssh args]"

          opts.separator ""

          opts.on("-c", "--command COMMAND", "Execute an SSH command directly.") do |c|
            options[:command] = c
          end
          opts.on("-p", "--plain", "Plain mode, leaves authentication up to user.") do |p|
            options[:plain_mode] = p
          end
        end

        # Parse the options and return if we don't have any target.
        argv = parse_options(opts)
        return if !argv

        # Parse out the extra args to send to SSH, which is everything
        # after the "--"
        ssh_args = ARGV.drop_while { |i| i != "--" }
        ssh_args = ssh_args[1..-1]
        options[:ssh_args] = ssh_args

        # If the remaining arguments ARE the SSH arguments, then just
        # clear it out. This happens because optparse returns what is
        # after the "--" as remaining ARGV, and Vagrant can think it is
        # a multi-vm name (wrong!)
        argv = [] if argv == ssh_args

        # Execute the actual SSH
        with_target_vms(argv, :single_target => true) do |vm|
          # Basic checks that are required for proper SSH
          raise Errors::VMNotCreatedError if !vm.created?
          raise Errors::VMInaccessible if !vm.state == :inaccessible
          raise Errors::VMNotRunningError if vm.state != :running

          if options[:command]
            ssh_execute(vm, options[:command])
          else
            opts = {
              :plain_mode => options[:plain_mode],
              :extra_args => options[:ssh_args]
            }

            ssh_connect(vm, opts)
          end
        end

        # Success, exit status 0
        0
       end

      protected

      def ssh_execute(vm, command=nil)
        exit_status = 0

        @logger.debug("Executing command: #{command}")
        exit_status = vm.channel.execute(command, :error_check => false) do |type, data|
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

        # Exit with the exit status we got from executing the command
        exit exit_status
      end

      def ssh_connect(vm, opts)
        @logger.debug("`exec` into ssh prompt")
        vm.ssh.exec(opts)
      end
    end
  end
end
