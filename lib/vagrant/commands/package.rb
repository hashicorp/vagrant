module Vagrant
  class Commands
    # Export and package the current vm
    #
    # This command requires that an instance be powered off
    class Package < Base
      Base.subcommand "package", self
      description "Packages a vagrant environment for distribution"

      def execute(args=[])
        parse_options(args)

        if !options[:base]
          # Packaging a pre-existing environment
          env.require_persisted_vm
        else
          # Packaging a base box; that is a VM not tied to a specific
          # vagrant environment
          vm = VM.find(options[:base])
          vm.env = env if vm
          env.vm = vm

          error_and_exit(:vm_base_not_found, :name => options[:base]) unless vm
        end

        error_and_exit(:vm_power_off_to_package) unless env.vm.powered_off?
        env.vm.package(args[0], options[:include])
      end

      def options_spec(opts)
        opts.banner = "Usage: vagrant package [--base BASE] [--include FILES]"

        # Defaults
        options[:include] = []

        opts.on("--base [BASE]", "Name or UUID of VM to create a base box from") do |v|
          options[:base] = v
        end

        opts.on("--include x,y,z", Array, "List of files to include in the package") do |v|
          options[:include] = v
        end
      end
    end
  end
end