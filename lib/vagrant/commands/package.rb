module Vagrant
  class Commands
    # Export and package the current vm
    #
    # This command requires that an instance be powered off
    class Package < Base
      Base.subcommand "package", self
      description "Packages a vagrant environment for distribution"

      def execute(args=[])
        args = parse_options(args)

        if options[:base]
          package_base
        else
          package_single(args[0])
        end
      end

      def package_base
        # Packaging a base box; that is a VM not tied to a specific
        # vagrant environment
        vm = VM.find(options[:base], env)
        if !vm
          error_and_exit(:vm_base_not_found, :name => options[:base])
          return # for tests
        end

        package_vm(vm)
      end

      def package_single(name)
        if name.nil? && env.multivm?
          error_and_exit(:package_multivm)
          return
        end

        vm = if name.nil?
               env.vms.values.first
             else
               env.vms[name.to_sym]
             end

        if vm.nil?
          error_and_exit(:unknown_vm, :vm => name)
          return
        elsif !vm.created?
          error_and_exit(:environment_not_created)
          return
        end

        package_vm(vm)
      end

      def package_vm(vm)
        vm.package(options)
      end

      def options_spec(opts)
        opts.banner = "Usage: vagrant package [--base BASE] [--output FILENAME] [--include FILES]"

        # Defaults
        options[:base] = nil
        options["package.output"] = nil
        options["package.include"] = []

        opts.on("--base BASE", "Name or UUID of VM to create a base box from") do |v|
          options[:base] = v
        end

        opts.on("--include x,y,z", Array, "List of files to include in the package") do |v|
          options["package.include"] = v
        end

        opts.on("-o", "--output FILE", "File to save the package as.") do |v|
          options["package.output"] = v
        end
      end
    end
  end
end
