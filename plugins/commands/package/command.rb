require 'optparse'
require 'securerandom'

module VagrantPlugins
  module CommandPackage
    class Command < Vagrant.plugin("2", :command)
      def self.synopsis
        "packages a running vagrant environment into a box"
      end

      def execute
        options = {}

        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant package [options] [name|id]"
          o.separator ""
          o.separator "Options:"
          o.separator ""

          o.on("--base NAME", "Name of a VM in VirtualBox to package as a base box (VirtualBox Only)") do |b|
            options[:base] = b
          end

          o.on("--output NAME", "Name of the file to output") do |output|
            options[:output] = output
          end

          o.on("--include FILE,FILE..", Array, "Comma separated additional files to package with the box") do |i|
            options[:include] = i
          end

          o.on("--vagrantfile FILE", "Vagrantfile to package with the box") do |v|
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
        tmp_data_directory = File.join(@env.tmp_path, SecureRandom.uuid)
        FileUtils.mkdir_p(tmp_data_directory)
        begin
          vm = Vagrant::Machine.new(
            options[:base],
            :virtualbox, provider[0], nil, provider[1],
            @env.vagrantfile.config,
            Pathname.new(tmp_data_directory), nil,
            @env, @env.vagrantfile, true)
          @logger.debug("Packaging base VM: #{vm.name}")
          package_vm(vm, options)
        ensure
          FileUtils.rm_rf(tmp_data_directory)
        end
      end

      def package_target(name, options)
        with_target_vms(name, single_target: true) do |vm|
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
