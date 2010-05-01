module Vagrant
  class Commands
    # Outputs the status of the current environment. This command outputs
    # useful information such as whether or not the environment is created
    # and if its running, suspended, etc.
    class Status < Base
      Base.subcommand "status", self
      description "Shows the status of the Vagrant environment."

      def execute(args=[])
        parse_options(args)

        if !options[:global]
          show_local_status
        else
          show_global_status
        end
      end

      # Shows the status of the CURRENT environment (the current working
      # directory). This prints out a human friendly sentence or paragraph
      # describing the state of the Vagrant environment represented by the
      # current working directory.
      def show_local_status
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

      # Shows the status of the GLOBAL Vagrant environment. This prints out
      # a listing of the virtual machines which Vagrant manages (running or
      # not).
      def show_global_status
        entries = []

        env.active_list.list.each do |uuid, data|
          vm = Vagrant::VM.find(uuid, env)
          entries << Translator.t(:status_global_entry, {
            :vm => vm,
            :data => data
          })
        end

        wrap_output { puts Translator.t(:status_global, :entries => entries) }
      end

      def options_spec(opts)
        opts.banner = "Usage: vagrant status [--global]"

        # Defaults
        options[:global] = false

        opts.on("-g", "--global", "Show global status of Vagrant (running VMs managed by Vagrant)") do |v|
          options[:global] = true
        end
      end
    end
  end
end