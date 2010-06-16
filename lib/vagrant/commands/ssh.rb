module Vagrant
  class Commands
    # Reload the environment. This is almost equivalent to the {up} command
    # except that it doesn't import the VM and do the initialize bootstrapping
    # of the instance. Instead, it forces a shutdown (if its running) of the
    # VM, updates the metadata (shared folders, forwarded ports), restarts
    # the VM, and then reruns the provisioning if enabled.
    class SSH < Base
      Base.subcommand "ssh", self
      description "SSH into the currently running environment"

      def execute(args=[])
        args = parse_options(args)
        if !options[:execute].empty?
          vms = args[0] ? {args[0] => env.vms[args[0].to_sym]} : env.vms
          vms.each do |name, vm|
            ssh_execute(name, vm)
          end
        else
          ssh_connect(args[0])
        end
      end

      def ssh_execute(name, vm)
        if vm.nil?
          error_and_exit(:unknown_vm, :vm => name)
          return # for tests
        elsif !vm.created?
          error_and_exit(:environment_not_created)
          return
        end

        vm.ssh.execute do |ssh|
          options[:execute].each do |command|
            vm.env.logger.info("Execute: #{command}")
            ssh.exec!(command) do |channel, type, data|
              # TODO: Exit status checking?
              vm.env.logger.info("#{type}: #{data}")
            end
          end
        end
      end

      def ssh_connect(name)
        if name.nil? && env.multivm?
          if env.primary_vm.nil?
            error_and_exit(:ssh_multivm)
            return # for tests
          end
        end

        vm = name.nil? ? env.primary_vm :  env.vms[name.to_sym]
        if vm.nil?
          error_and_exit(:unknown_vm, :vm => name)
          return # for tests
        end

        if !vm.created?
          error_and_exit(:environment_not_created)
          return
        else
          vm.ssh.connect
        end
      end

      def options_spec(opts)
        opts.banner = "Usage: vagrant ssh [--execute COMMAND]"

        # Defaults
        options[:execute] = []

        opts.on("-e", "--execute COMMAND", "A command to execute. Multiple -e's may be specified.") do |value|
          options[:execute] << value
        end
      end
    end
  end
end
