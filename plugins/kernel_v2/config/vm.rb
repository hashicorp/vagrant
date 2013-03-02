require "pathname"
require "securerandom"

require "vagrant"
require "vagrant/config/v2/util"

require File.expand_path("../vm_provisioner", __FILE__)
require File.expand_path("../vm_subvm", __FILE__)

module VagrantPlugins
  module Kernel_V2
    class VMConfig < Vagrant.plugin("2", :config)
      DEFAULT_VM_NAME = :default

      attr_accessor :base_mac
      attr_accessor :box
      attr_accessor :box_url
      attr_accessor :graceful_halt_retry_count
      attr_accessor :graceful_halt_retry_interval
      attr_accessor :guest
      attr_accessor :hostname
      attr_accessor :usable_port_range
      attr_reader :synced_folders
      attr_reader :provisioners

      def initialize
        @graceful_halt_retry_count    = UNSET_VALUE
        @graceful_halt_retry_interval = UNSET_VALUE
        @hostname                     = UNSET_VALUE
        @synced_folders               = {}
        @provisioners                 = []

        # Internal state
        @__compiled_provider_configs = {}
        @__finalized = false
        @__networks  = {}
        @__providers = {}
      end

      # Custom merge method since some keys here are merged differently.
      def merge(other)
        super.tap do |result|
          other_networks = other.instance_variable_get(:@__networks)

          result.instance_variable_set(:@__networks, @__networks.merge(other_networks))
          result.instance_variable_set(:@synced_folders, @synced_folders.merge(other.synced_folders))
          result.instance_variable_set(:@provisioners, @provisioners + other.provisioners)

          # Merge the providers by prepending any configuration blocks we
          # have for providers onto the new configuration.
          other_providers = other.instance_variable_get(:@__providers)
          new_providers   = @__providers.dup
          other_providers.each do |key, blocks|
            new_providers[key] ||= []
            new_providers[key] += blocks
          end

          result.instance_variable_set(:@__providers, new_providers)
        end
      end

      # Defines a synced folder pair. This pair of folders will be synced
      # to/from the machine. Note that if the machine you're using doesn't
      # support multi-directional syncing (perhaps an rsync backed synced
      # folder) then the host is always synced to the guest but guest data
      # may not be synced back to the host.
      #
      # @param [String] hostpath Path to the host folder to share. If this
      #   is a relative path, it is relative to the location of the
      #   Vagrantfile.
      # @param [String] guestpath Path on the guest to mount the shared
      #   folder.
      # @param [Hash] options Additional options.
      def synced_folder(hostpath, guestpath, options=nil)
        options ||= {}
        options[:id] ||= guestpath
        options[:guestpath] = guestpath
        options[:hostpath]  = hostpath

        @synced_folders[options[:id]] = options
      end

      # Define a way to access the machine via a network. This exposes a
      # high-level abstraction for networking that may not directly map
      # 1-to-1 for every provider. For example, AWS has no equivalent to
      # "port forwarding." But most providers will attempt to implement this
      # in a way that behaves similarly.
      #
      # `type` can be one of:
      #
      #   * `:forwarded_port` - A port that is accessible via localhost
      #     that forwards into the machine.
      #   * `:private_network` - The machine gets an IP that is not directly
      #     publicly accessible, but ideally accessible from this machine.
      #   * `:public_network` - The machine gets an IP on a shared network.
      #
      # @param [Symbol] type Type of network
      # @param [Hash] options Options for the network.
      def network(type, options=nil)
        options ||= {}
        id      = options[:id] || SecureRandom.uuid

        # Scope the ID by type so that different types can share IDs
        id      = "#{type}-#{id}"

        # Merge in the previous settings if we have them.
        if @__networks.has_key?(id)
          options = @__networks[id][1].merge(options)
        end

        # Merge in the latest settings and set the internal state
        @__networks[id] = [type, options]
      end

      # Configures a provider for this VM.
      #
      # @param [Symbol] name The name of the provider.
      def provider(name, &block)
        @__providers[name] ||= []
        @__providers[name] << block if block_given?
      end

      def provision(name, options=nil, &block)
        @provisioners << VagrantConfigProvisioner.new(name, options, &block)
      end

      def defined_vms
        @defined_vms ||= {}
      end

      # This returns the keys of the sub-vms in the order they were
      # defined.
      def defined_vm_keys
        @defined_vm_keys ||= []
      end

      def define(name, options=nil, &block)
        name = name.to_sym
        options ||= {}
        options[:config_version] ||= "2"

        # Add the name to the array of VM keys. This array is used to
        # preserve the order in which VMs are defined.
        defined_vm_keys << name

        # Add the SubVM to the hash of defined VMs
        if !defined_vms[name]
          defined_vms[name] ||= VagrantConfigSubVM.new
        end

        defined_vms[name].options.merge!(options)
        defined_vms[name].config_procs << [options[:config_version], block] if block
      end

      #-------------------------------------------------------------------
      # Internal methods, don't call these.
      #-------------------------------------------------------------------

      def finalize!
        # If we haven't defined a single VM, then we need to define a
        # default VM which just inherits the rest of the configuration.
        define(DEFAULT_VM_NAME) if defined_vm_keys.empty?

        # Compile all the provider configurations
        @__providers.each do |name, blocks|
          # Find the configuration class for this provider
          config_class = Vagrant.plugin("2").manager.provider_configs[name]
          next if !config_class

          # Load it up
          config = config_class.new
          blocks.each { |b| b.call(config) }
          config.finalize!

          # Store it for retrieval later
          @__compiled_provider_configs[name] = config
        end

        # Flag that we finalized
        @__finalized = true
      end

      # This returns the compiled provider-specific configurationf or the
      # given provider.
      #
      # @param [Symbol] name Name of the provider.
      def get_provider_config(name)
        raise "Must finalize first." if !@__finalized

        result = @__compiled_provider_configs[name]

        # If no compiled configuration was found, then we try to just
        # use the default configuration from the plugin.
        if !result
          config_class = Vagrant.plugin("2").manager.provider_configs[name]
          if config_class
            result = config_class.new
            result.finalize!
          end
        end

        return result
      end

      # This returns the list of networks configured.
      def networks
        @__networks.values
      end

      def validate(machine)
        errors = []
        errors << I18n.t("vagrant.config.vm.box_missing") if !box
        errors << I18n.t("vagrant.config.vm.box_not_found", :name => box) if \
          box && !box_url && !machine.box

        has_nfs = false
        @synced_folders.each do |id, options|
          hostpath = Pathname.new(options[:hostpath]).expand_path(machine.env.root_path)

          if !hostpath.directory? && !options[:create]
            errors << I18n.t("vagrant.config.vm.shared_folder_hostpath_missing",
                             :path => options[:hostpath])
          end

          if options[:nfs]
            has_nfs = true

            if options[:owner] || options[:group]
              # Owner/group don't work with NFS
              errors << I18n.t("vagrant.config.vm.shared_folder_nfs_owner_group",
                               :path => options[:hostpath])
            end
          end
        end

        if has_nfs
          if !machine.env.host
            errors << I18n.t("vagrant.config.vm.nfs_requires_host")
          else
            errors << I18n.t("vagrant.config.vm.nfs_not_supported") if \
              !machine.env.host.nfs?
          end
        end

        # We're done with VM level errors so prepare the section
        errors = { "vm" => errors }

        # Validate only the _active_ provider
        if machine.provider_config
          provider_errors = machine.provider_config.validate(machine)
          if provider_errors
            errors = Vagrant::Config::V2::Util.merge_errors(errors, provider_errors)
          end
        end

        # Validate provisioners
        @provisioners.each do |vm_provisioner|
          if vm_provisioner.config
            provisioner_errors = vm_provisioner.config.validate(machine)
            if provisioner_errors
              errors = Vagrant::Config::V2::Util.merge_errors(errors, provisioner_errors)
            end
          end
        end

        errors
      end
    end
  end
end
