module VagrantPlugins
  module Kernel_V1
    # This is the Version 1.0.x Vagrant VM configuration. This is
    # _outdated_ and exists purely to be upgraded over to the new V2
    # format.
    class VMConfig < Vagrant.plugin("1", :config)
      DEFAULT_VM_NAME = :default

      attr_accessor :name
      attr_accessor :auto_port_range
      attr_accessor :base_mac
      attr_accessor :boot_mode
      attr_accessor :box
      attr_accessor :box_url
      attr_accessor :guest
      attr_accessor :host_name
      attr_reader :customizations
      attr_reader :networks
      attr_reader :provisioners
      attr_reader :shared_folders

      def initialize
        @shared_folders = {}
        @networks = []
        @provisioners = []
        @customizations = []
        @define_calls = []
      end

      def forward_port(guestport, hostport, options=nil)
        # Build up the network options for V2
        network_options = {}
        network_options[:virtualbox__adapter] = options[:adapter]
        network_options[:virtualbox__protocol] = options[:protocol]

        # Just append the forwarded port to the networks
        @networks << [:forwarded_port, guestport, hostport, network_options]
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
        @provisioners << [name, options, block]
      end

      # This argument is nil only because the old style was deprecated and
      # we didn't want to break Vagrantfiles. This was never removed and
      # since we've moved onto V2 configuration, we might as well keep this
      # around forever.
      def customize(command=nil)
        @customizations << command if command
      end

      def define(name, options=nil, &block)
        @define_calls << [name, options, block]
      end

      def finalize!
        # If we haven't defined a single VM, then we need to define a
        # default VM which just inherits the rest of the configuration.
        define(DEFAULT_VM_NAME) if defined_vm_keys.empty?
      end

      # Upgrade to a V2 configuration
      def upgrade(new)
        new.vm.base_mac          = self.base_mac if self.base_mac
        new.vm.box               = self.box if self.box
        new.vm.box_url           = self.box_url if self.box_url
        new.vm.guest             = self.guest if self.guest
        new.vm.host_name         = self.host_name if self.host_name
        new.vm.usable_port_range = self.auto_port_range if self.auto_port_range

        if self.boot_mode
          # Enable the GUI if the boot mode is GUI.
          new.vm.providers[:virtualbox].config.gui = (self.boot_mode.to_s == "gui")
        end

        # If we have VM customizations, then we enable them on the
        # VirtualBox provider on the new VM.
        self.customizations.each do |customization|
          new.vm.providers[:virtualbox].config.customize(customization)
        end

        # Re-define all networks.
        self.networks.each do |type, args|
          new.vm.network(type, *args)
        end

        # Provisioners
        self.provisioners.each do |name, options, block|
          new.vm.provision(name, options, &block)
        end

        # Shared folders
        self.shared_folders.each do |name, sf|
          options = sf.dup
          guestpath = options.delete(:guestpath)
          hostpath = options.delete(:hostpath)

          new.vm.share_folder(name, guestpath, hostpath, options)
        end

        # Defined sub-VMs
        @define_calls.each do |name, options, block|
          new.vm.define(name, options, &block)
        end

        # XXX: Warning: `vm.name` is useless now
      end
    end
  end
end
