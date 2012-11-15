require "pathname"

require "vagrant"

require File.expand_path("../vm_provisioner", __FILE__)
require File.expand_path("../vm_subvm", __FILE__)

module VagrantPlugins
  module Kernel_V1
    class VMConfig < Vagrant.plugin("1", :config)
      DEFAULT_VM_NAME = :default

      attr_accessor :name
      attr_accessor :auto_port_range
      attr_accessor :box
      attr_accessor :box_url
      attr_accessor :base_mac
      attr_accessor :boot_mode
      attr_accessor :host_name
      attr_reader :forwarded_ports
      attr_reader :shared_folders
      attr_reader :networks
      attr_reader :provisioners
      attr_reader :customizations
      attr_accessor :guest

      def initialize
        @forwarded_ports = []
        @shared_folders = {}
        @networks = []
        @provisioners = []
        @customizations = []
      end

      # Custom merge method since some keys here are merged differently.
      def merge(other)
        result = super
        result.instance_variable_set(:@forwarded_ports, @forwarded_ports + other.forwarded_ports)
        result.instance_variable_set(:@shared_folders, @shared_folders.merge(other.shared_folders))
        result.instance_variable_set(:@networks, @networks + other.networks)
        result.instance_variable_set(:@provisioners, @provisioners + other.provisioners)
        result.instance_variable_set(:@customizations, @customizations + other.customizations)
        result
      end

      def forward_port(guestport, hostport, options=nil)
        @forwarded_ports << {
          :name       => "#{guestport.to_s(32)}-#{hostport.to_s(32)}",
          :guestport  => guestport,
          :hostport   => hostport,
          :protocol   => :tcp,
          :adapter    => 1,
          :auto       => false
        }.merge(options || {})
      end

      def share_folder(name, guestpath, hostpath, opts=nil)
        @shared_folders[name] = {
          :guestpath => guestpath.to_s,
          :hostpath => hostpath.to_s,
          :create => false,
          :owner => nil,
          :group => nil,
          :nfs   => false,
          :transient => false,
          :extra => nil
        }.merge(opts || {})
      end

      def network(type, *args)
        @networks << [type, args]
      end

      def provision(name, options=nil, &block)
        @provisioners << VagrantConfigProvisioner.new(name, options, &block)
      end

      # TODO: This argument should not be `nil` in the future.
      # It is only defaulted to nil so that the deprecation error
      # can be properly shown.
      def customize(command=nil)
        @customizations << command if command
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

        # Add the name to the array of VM keys. This array is used to
        # preserve the order in which VMs are defined.
        defined_vm_keys << name

        # Add the SubVM to the hash of defined VMs
        if !defined_vms[name]
          # If it hasn't been defined before, then create the sub-VM configuration
          # and configure it so that it has the proper name.
          defined_vms[name] ||= VagrantConfigSubVM.new
          defined_vms[name].push_proc do |config|
            config.vm.name = name
          end
        end

        defined_vms[name].options.merge!(options)
        defined_vms[name].push_proc(&block) if block
      end

      def finalize!
        # If we haven't defined a single VM, then we need to define a
        # default VM which just inherits the rest of the configuration.
        define(DEFAULT_VM_NAME) if defined_vm_keys.empty?
      end

      # Upgrade to a V2 configuration
      def upgrade(new)
        new.vm.auto_port_range = self.auto_port_range
        new.vm.base_mac = self.base_mac
        new.vm.boot_mode = self.boot_mode
        new.vm.box = self.box
        new.vm.box_url = self.box_url
        new.vm.guest = self.guest
        new.vm.host_name = self.host_name

        # XXX: Warning: `vm.name` is useless now
      end
    end
  end
end
