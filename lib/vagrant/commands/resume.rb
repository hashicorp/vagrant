module Vagrant
  class Commands
    # Resume a running vagrant instance. This resumes an already suspended
    # instance (from {suspend}).
    #
    # This command requires that an instance already be brought up with
    # `vagrant up`.
    class Resume < Base
      Base.subcommand "resume", self
      description "Resumes a suspend vagrant environment"

      def execute(args=[])
        all_or_single(args, :resume)
      end

      def resume_single(name)
        vm = env.vms[name.to_sym]
        if vm.nil?
          error_and_exit(:unknown_vm, :vm => name)
          return # for tests
        end

        if vm.created?
          vm.resume
        else
          vm.env.logger.info "VM '#{name}' not created. Ignoring."
        end
      end

      def options_spec(opts)
        opts.banner = "Usage: vagrant resume"
      end
    end
  end
end
