module Vagrant
  module Command
    class PackageCommand < NamedBase
      class_option :base, :type => :string, :default => nil
      class_option :output, :type => :string, :default => nil
      class_option :include, :type => :array, :default => nil
      class_option :vagrantfile, :type => :string, :default => nil
      register "package", "Package a Vagrant environment for distribution"

      def execute
        return package_base if options[:base]
        package_target
      end

      protected

      def package_base
        Vagrant.log.verbose "Searching for VM named \"#{options[:base]}\""
        vm = VM.find(options[:base], env)
        raise Errors::BaseVMNotFound, :name => options[:base] if !vm.created?
        package_vm(vm)
      end

      def package_target
        raise Errors::MultiVMTargetRequired, :command => "package" if target_vms.length > 1
        vm = target_vms.first
        raise Errors::VMNotCreatedError if !vm.created?
        package_vm(vm)
      end

      def package_vm(vm)
        opts = options.inject({}) do |acc, data|
          k,v = data
          acc["package.#{k}"] = v
          acc
        end

        vm.package(opts)
      end
    end
  end
end
