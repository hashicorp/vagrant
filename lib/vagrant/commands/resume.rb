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
        env.require_persisted_vm
        env.vm.resume
      end

      def options_spec(opts)
        opts.banner = "Usage: vagrant resume"
      end
    end
  end
end