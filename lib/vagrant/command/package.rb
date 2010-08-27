module Vagrant
  module Command
    class PackageCommand < NamedBase
      desc "Package a Vagrant environment for distribution"
      class_option :base, :type => :string, :default => nil
      class_option :output, :type => :string, :default => nil
      class_option :include, :type => :array, :default => nil
      register "package"

      def execute
        return package_base if options[:base]
        package_target
      end

      protected

      def package_base
        vm = VM.find(options[:base], env)
        raise Errors::BaseVMNotFoundError.new(:name => options[:base]) if !vm.created?
        package_vm(vm)
      end

      def package_target
        raise Errors::MultiVMTargetRequired.new(:command => "package") if target_vms.length > 1
        vm = target_vms.first
        raise Errors::VMNotCreatedError.new if !vm.created?
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
