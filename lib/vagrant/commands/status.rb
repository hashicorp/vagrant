module Vagrant
  class Commands
    # Outputs the status of the current environment. This command outputs
    # useful information such as whether or not the environment is created
    # and if its running, suspended, etc.
    class Status < Base
      Base.subcommand "status", self
      description "Shows the status of the current environment."

      def execute(args=[])
        string_key = nil

        if !env.root_path
          string_key = :status_no_environment
        elsif !env.vm
          string_key = :status_not_created
        else
          additional_key = nil
          if env.vm.vm.running?
            additional_key = :status_created_running
          elsif env.vm.vm.saved?
            additional_key = :status_created_saved
          elsif env.vm.vm.powered_off?
            additional_key = :status_created_powered_off
          end

          string_key = [:status_created, {
            :vm_state => env.vm.vm.state,
            :additional_message => additional_key ? Translator.t(additional_key) : ""
          }]
        end

        string_key = [string_key, {}] unless string_key.is_a?(Array)
        wrap_output { puts Translator.t(*string_key) }
      end

      def options_spec(opts)
        opts.banner = "Usage: vagrant status"
      end
    end
  end
end