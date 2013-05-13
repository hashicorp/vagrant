require 'optparse'

module VagrantPlugins
  module CommandSSH
    class Command < Vagrant.plugin("2", :command)
      def execute
        options = {}

        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant ssh [vm-name] [-c command] [-- extra ssh args]"

          o.separator ""

          o.on("-c", "--command COMMAND", "Execute an SSH command directly.") do |c|
            options[:command] = c
          end

          o.on("-p", "--plain", "Plain mode, leaves authentication up to user.") do |p|
            options[:plain_mode] = p
          end
        end

        # Parse out the extra args to send to SSH, which is everything
        # after the "--"
        split_index = @argv.index("--")
        if split_index
          options[:ssh_args] = @argv.drop(split_index + 1)
          @argv              = @argv.take(split_index)
        end

        # Parse the options and return if we don't have any target.
        argv = parse_options(opts)
        return if !argv

        # Execute the actual SSH
        with_target_vms(argv, :single_target => true) do |vm|
          if options[:command]
            @logger.debug("Executing single command on remote machine: #{options[:command]}")
            env = vm.action(:ssh_run, :ssh_run_command => options[:command])

            # Exit with the exit status of the command or a 0 if we didn't
            # get one.
            exit_status = env[:ssh_run_exit_status] || 0
            return exit_status
          else
            opts = {
              :plain_mode => options[:plain_mode],
              :extra_args => options[:ssh_args]
            }

            @logger.debug("Invoking `ssh` action on machine")
            vm.action(:ssh, :ssh_opts => opts)

            # We should never reach this point, since the point of `ssh`
            # is to exec into the proper SSH shell, but we'll just return
            # an exit status of 0 anyways.
            return 0
          end
        end
      end
    end
  end
end
