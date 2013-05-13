require 'optparse'

module VagrantPlugins
  module CommandPackage
    class Command < Vagrant.plugin("2", :command)
      def execute
        options = {}

        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant package [vm-name] [--base name] [--output name.box]"
          o.separator "                       [--include one,two,three] [--vagrantfile file]"

          o.separator ""

          o.on("--base NAME", "Name of a VM in virtualbox to package as a base box") do |b|
            options[:base] = b
          end

          o.on("--output NAME", "Name of the file to output") do |output|
            options[:output] = output
          end

          o.on("--include x,y,z", Array, "Additional files to package with the box.") do |i|
            options[:include] = i
          end

          o.on("--vagrantfile file", "Vagrantfile to package with the box.") do |v|
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
        # XXX: This whole thing is hardcoded and very temporary. The whole
        # `vagrant package --base` process is deprecated for something much
        # better in the future. We just hardcode this to keep VirtualBox working
        # for now.
        provider = Vagrant.plugin("2").manager.providers[:virtualbox]
        vm = Vagrant::Machine.new(
          options[:base],
          :virtualbox, provider[0], nil, provider[1],
          @env.config_global,
          nil, nil,
          @env, true)
        @logger.debug("Packaging base VM: #{vm.name}")
        package_vm(vm, options)
      end

      def package_target(name, options)
        with_target_vms(name, :single_target => true) do |vm|
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

        vm.action(:package, opts)
      end
    end
  end
end
