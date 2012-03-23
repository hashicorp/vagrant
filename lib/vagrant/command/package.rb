require 'optparse'

module Vagrant
  module Command
    class Package < Base
      def execute
        options = {}

        opts = OptionParser.new do |opts|
          opts.banner = "Usage: vagrant package [vm-name] [--base name] [--output name.box]"
          opts.separator "                       [--include one,two,three] [--vagrantfile file]"

          opts.separator ""

          opts.on("--base NAME", "Name of a VM in virtualbox to package as a base box") do |b|
            options[:base] = b
          end

          opts.on("--output NAME", "Name of the file to output") do |o|
            options[:output] = o
          end

          opts.on("--include x,y,z", Array, "Additional files to package with the box.") do |i|
            options[:include] = i
          end

          opts.on("--vagrantfile file", "Vagrantfile to package with the box.") do |v|
            options[:vagrantfile] = v
          end
        end

        # Parse the options
        argv = parse_options(opts)
        return if !argv

        @logger.debug("package options: #{options.inspect}")
        if options[:base]
          package_base(options)
        else
          package_target(argv[0], options)
        end

        # Success, exit status 0
        0
       end

      protected

      def package_base(options)
        vm = VM.new(options[:base], @env, @env.config.global, :base => true)
        raise Errors::BaseVMNotFound, :name => options[:base] if !vm.created?
        @logger.debug("Packaging base VM: #{vm.name}")
        package_vm(vm, options)
      end

      def package_target(name, options)
        with_target_vms(name, :single_target => true) do |vm|
          raise Errors::VMNotCreatedError if !vm.created?
          @logger.debug("Packaging VM: #{vm.name}")
          package_vm(vm, options)
        end
      end

      def package_vm(vm, options)
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
