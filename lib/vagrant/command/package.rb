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
        raise VMNotFoundError.new("Specified base VM not found: #{options[:base]}") if !vm.created?
        vm.package(options)
      end

      def package_target
        raise MultiVMTargetRequired.new("`vagrant package` requires the name of the VM to package in a multi-vm environment.") if target_vms.length > 1
        vm = target_vms.first
        raise VMNotCreatedError.new("The VM must be created to package it. Run `vagrant up` first.") if !vm.created?
        vm.package(options)
      end
    end
  end
end
