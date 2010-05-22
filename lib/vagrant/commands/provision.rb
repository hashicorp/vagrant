module Vagrant
  class Commands
    #run the provisioner on a running vm
    class Provision < Base
      Base.subcommand "provision", self
      description "Run the provisioner"

      def execute(args=[])
        all_or_single(args, :provision)
      end

      def provision_single(name)
        vm = env.vms[name.to_sym]
        if vm.nil?
          error_and_exit(:unknown_vm, :vm => name)
          return # for tests
        end

        if vm.vm.running?
          vm.provision
        else
          vm.env.logger.info "VM '#{name}' not running. Ignoring provision request."
        end
      end

      def options_spec(opts)
        opts.banner = "Usage: vagrant provision"
      end
    end
  end
end
