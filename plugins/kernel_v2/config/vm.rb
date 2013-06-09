require "pathname"
require "securerandom"
require "set"

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
      attr_reader :provisioners

      def initialize
        @graceful_halt_retry_count    = UNSET_VALUE
        @graceful_halt_retry_interval = UNSET_VALUE
        @guest                        = UNSET_VALUE
        @hostname                     = UNSET_VALUE
        @provisioners                 = []

        # Internal state
        @__compiled_provider_configs   = {}
        @__defined_vm_keys             = []
        @__defined_vms                 = {}
        @__finalized                   = false
        @__networks                    = {}
        @__providers                   = {}
        @__provider_overrides          = {}
        @__synced_folders              = {}
      end

      # Custom merge method since some keys here are merged differently.
      def merge(other)
        super.tap do |result|
          other_networks = other.instance_variable_get(:@__networks)

          result.instance_variable_set(:@__networks, @__networks.merge(other_networks))
          result.instance_variable_set(:@provisioners, @provisioners + other.provisioners)

          # Merge defined VMs by first merging the defined VM keys,
          # preserving the order in which they were defined.
          other_defined_vm_keys = other.instance_variable_get(:@__defined_vm_keys)
          other_defined_vm_keys -= @__defined_vm_keys
          new_defined_vm_keys   = @__defined_vm_keys + other_defined_vm_keys

          # Merge the actual defined VMs.
          other_defined_vms = other.instance_variable_get(:@__defined_vms)
          new_defined_vms   = {}

          @__defined_vms.each do |key, subvm|
            new_defined_vms[key] = subvm.clone
          end

          other_defined_vms.each do |key, subvm|
            if !new_defined_vms.has_key?(key)
              new_defined_vms[key] = subvm.clone
            else
              new_defined_vms[key].config_procs.concat(subvm.config_procs)
              new_defined_vms[key].options.merge!(subvm.options)
            end
          end

          # Merge the providers by prepending any configuration blocks we
          # have for providers onto the new configuration.
          other_providers = other.instance_variable_get(:@__providers)
          new_providers   = @__providers.dup
          other_providers.each do |key, blocks|
            new_providers[key] ||= []
            new_providers[key] += blocks
          end

          # Merge the provider overrides by appending them...
          other_overrides = other.instance_variable_get(:@__provider_overrides)
          new_overrides   = @__provider_overrides.dup
          other_overrides.each do |key, blocks|
            new_overrides[key] ||= []
            new_overrides[key] += blocks
          end

          # Merge synced folders.
          other_folders = other.instance_variable_get(:@__synced_folders)
          new_folders = @__synced_folders.dup
          other_folders.each do |id, options|
            new_folders[id] ||= {}
            new_folders[id].merge!(options)
          end

          result.instance_variable_set(:@__defined_vm_keys, new_defined_vm_keys)
          result.instance_variable_set(:@__defined_vms, new_defined_vms)
          result.instance_variable_set(:@__providers, new_providers)
          result.instance_variable_set(:@__provider_overrides, new_overrides)
          result.instance_variable_set(:@__synced_folders, new_folders)
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
        options[:guestpath] = guestpath.to_s.gsub(/\/$/, '')
        options[:hostpath]  = hostpath

        @__synced_folders[options[:guestpath]] = options
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

        if !options[:id]
          default_id = nil

          if type == :forwarded_port
            # For forwarded ports, set the default ID to the
            # host port so that host ports overwrite each other.
            default_id = options[:host]
          end

          options[:id] = default_id || SecureRandom.uuid
        end

        # Scope the ID by type so that different types can share IDs
        id      = options[:id]
        id      = "#{type}-#{id}"

        # Merge in the previous settings if we have them.
        if @__networks.has_key?(id)
          options = @__networks[id][1].merge(options)
        end

        # Merge in the latest settings and set the internal state
        @__networks[id] = [type.to_sym, options]
      end

      # Configures a provider for this VM.
      #
      # @param [Symbol] name The name of the provider.
      def provider(name, &block)
        name = name.to_sym
        @__providers[name] ||= []
        @__provider_overrides[name] ||= []

        if block_given?
          @__providers[name] << block if block_given?

          # If this block takes two arguments, then we curry it and store
          # the configuration override for use later.
          if block.arity == 2
            @__provider_overrides[name] << block.curry[Vagrant::Config::V2::DummyConfig.new]
          end
        end
      end

      def provision(name, options=nil, &block)
        @provisioners << VagrantConfigProvisioner.new(name.to_sym, options, &block)
      end

      def defined_vms
        @__defined_vms
      end

      # This returns the keys of the sub-vms in the order they were
      # defined.
      def defined_vm_keys
        @__defined_vm_keys
      end

      def define(name, options=nil, &block)
        name = name.to_sym
        options ||= {}
        options[:config_version] ||= "2"

        # Add the name to the array of VM keys. This array is used to
        # preserve the order in which VMs are defined.
        @__defined_vm_keys << name if !@__defined_vm_keys.include?(name)

        # Add the SubVM to the hash of defined VMs
        if !@__defined_vms[name]
          @__defined_vms[name] = VagrantConfigSubVM.new
        end

        @__defined_vms[name].options.merge!(options)
        @__defined_vms[name].config_procs << [options[:config_version], block] if block
      end

      #-------------------------------------------------------------------
      # Internal methods, don't call these.
      #-------------------------------------------------------------------

      def finalize!
        # Defaults
        @guest = nil if @guest == UNSET_VALUE
        @hostname = nil if @hostname == UNSET_VALUE

        # Set the guest properly
        @guest = @guest.to_sym if @guest

        # If we haven't defined a single VM, then we need to define a
        # default VM which just inherits the rest of the configuration.
        define(DEFAULT_VM_NAME) if defined_vm_keys.empty?

        # Compile all the provider configurations
        @__providers.each do |name, blocks|
          # If we don't have any configuration blocks, then ignore it
          next if blocks.empty?

          # Find the configuration class for this provider
          config_class = Vagrant.plugin("2").manager.provider_configs[name]
          config_class ||= Vagrant::Config::V2::DummyConfig

          # Load it up
          config    = config_class.new

          blocks.each do |b|
            b.call(config, Vagrant::Config::V2::DummyConfig.new)
          end

          config.finalize!

          # Store it for retrieval later
          @__compiled_provider_configs[name]   = config
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

      # This returns a list of VM configurations that are overrides
      # for this provider.
      #
      # @param [Symbol] name Name of the provider
      # @return [Array<Proc>]
      def get_provider_overrides(name)
        (@__provider_overrides[name] || []).map do |p|
          ["2", p]
        end
      end

      # This returns the list of networks configured.
      def networks
        @__networks.values
      end

      # This returns the list of synced folders
      def synced_folders
        @__synced_folders
      end

      def validate(machine)
        errors = _detected_errors
        errors << I18n.t("vagrant.config.vm.box_missing") if !box
        errors << I18n.t("vagrant.config.vm.box_not_found", :name => box) if \
          box && !box_url && !machine.box
        errors << I18n.t("vagrant.config.vm.hostname_invalid_characters") if \
          @hostname && @hostname !~ /^[-.a-z0-9]+$/i

        has_nfs = false
        used_guest_paths = Set.new
        @__synced_folders.each do |id, options|
          # If the shared folder is disabled then don't worry about validating it
          next if options[:disabled]

          guestpath = Pathname.new(options[:guestpath])
          hostpath  = Pathname.new(options[:hostpath]).expand_path(machine.env.root_path)

          if guestpath.relative?
            errors << I18n.t("vagrant.config.vm.shared_folder_guestpath_relative",
                             :path => options[:guestpath])
          else
            if used_guest_paths.include?(options[:guestpath])
              errors << I18n.t("vagrant.config.vm.shared_folder_guestpath_duplicate",
                               :path => options[:guestpath])
            end

            used_guest_paths.add(options[:guestpath])
          end

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

        # Validate networks
        has_fp_port_error = false
        fp_host_ports     = Set.new
        valid_network_types = [:forwarded_port, :private_network, :public_network]

        networks.each do |type, options|
          if !valid_network_types.include?(type)
            errors << I18n.t("vagrant.config.vm.network_type_invalid",
                            :type => type.to_s)
          end

          if type == :forwarded_port
            if !has_fp_port_error && (!options[:guest] || !options[:host])
              errors << I18n.t("vagrant.config.vm.network_fp_requires_ports")
              has_fp_port_error = true
            end

            if options[:host]
              if fp_host_ports.include?(options[:host])
                errors << I18n.t("vagrant.config.vm.network_fp_host_not_unique",
                                :host => options[:host].to_s)
              end

              fp_host_ports.add(options[:host])
            end
          end

          if type == :private_network
            if options[:type] != :dhcp
              if !options[:ip]
                errors << I18n.t("vagrant.config.vm.network_ip_required")
              end
            end
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
          if vm_provisioner.invalid?
            errors["vm"] << I18n.t("vagrant.config.vm.provisioner_not_found",
                                   :name => vm_provisioner.name)
            next
          end

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
