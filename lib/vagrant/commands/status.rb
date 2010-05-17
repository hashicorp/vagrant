module Vagrant
  class Commands
    # Outputs the status of the current environment. This command outputs
    # useful information such as whether or not the environment is created
    # and if its running, suspended, etc.
    class Status < Base
      Base.subcommand "status", self
      description "Shows the status of the Vagrant environment."

      def execute(args=[])
        args = parse_options(args)
        if args.length > 1
          # There should never be more than 1 arg
          show_help
          return
        end

        if !options[:global]
          show_local_status(*args)
        else
          show_global_status
        end
      end

      # Shows the status of the CURRENT environment (the current working
      # directory). If a specific VM was given, it will print out
      # detailed information regarding that VM. If no single VM was
      # specified and it is a multi-VM environment, it will simply
      # show a listing of all the VMs and their short one word
      # statuses.
      def show_local_status(vm=nil)
        if !env.root_path
          wrap_output { puts Translator.t(:status_no_environment) }
          return
        end

        if vm.nil?
          if env.multivm?
            # No specific VM was specified in a multi-vm environment,
            # so show short info for each VM
            show_list
            return
          else
            # Set the VM to just be the root VM
            vm = env.vms.values.first
          end
        else
          # Try to get the vm based on the name. If the specified VM
          # doesn't exist, then error saying so
          vm = env.vms[vm.to_sym] || error_and_exit(:unknown_vm, :vm => vm)
        end

        show_single(vm)
      end

      # Lists the available VMs and brief statuses about each.
      def show_list
        wrap_output do
          puts Translator.t(:status_listing)
          puts ""

          env.vms.each do |name, vm|
            state = vm.created? ? vm.vm.state : "not created"
            puts "#{name.to_s.ljust(30)}#{state}"
          end
        end
      end

      # Shows a paragraph of information based on the current state of
      # a single, specified VM.
      def show_single(vm)
        string_key = nil

        if !vm.created?
          string_key = :status_not_created
        else
          additional_key = nil
          if vm.vm.running?
            additional_key = :status_created_running
          elsif vm.vm.saved?
            additional_key = :status_created_saved
          elsif vm.vm.powered_off?
            additional_key = :status_created_powered_off
          end

          string_key = [:status_created, {
            :vm_state => vm.vm.state,
            :additional_message => additional_key ? Translator.t(additional_key) : ""
          }]
        end

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
        options[:vm] = nil

        opts.on("-g", "--global", "Show global status of Vagrant (running VMs managed by Vagrant)") do |v|
          options[:global] = true
        end
      end
    end
  end
end
