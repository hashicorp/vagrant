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
        options ||= {}

        # Build up the network options for V2
        network_options = {}
        network_options[:virtualbox__adapter] = options[:adapter]
        network_options[:virtualbox__protocol] = options[:protocol]

        # Just append the forwarded port to the networks
        @networks << [:forwarded_port, [guestport, hostport, network_options]]
      end

      def share_folder(name, guestpath, hostpath, opts=nil)
        @shared_folders[name] = {
          guestpath: guestpath.to_s,
          hostpath: hostpath.to_s,
          create: false,
          owner: nil,
          group: nil,
          nfs:   false,
          transient: false,
          extra: nil
        }.merge(opts || {})
      end

      def network(type, *args)
        # Convert to symbol so we can allow most anything...
        type = type.to_sym if type

        if type == :hostonly
          @networks << [:private_network, args]
        elsif type == :bridged
          @networks << [:public_network, args]
        else
          @networks << [:unknown, type]
        end
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
        # Force the V1 config on these calls
        options ||= {}
        options[:config_version] = "1"

        @define_calls << [name, options, block]
      end

      def finalize!
        # If we haven't defined a single VM, then we need to define a
        # default VM which just inherits the rest of the configuration.
        define(DEFAULT_VM_NAME) if defined_vm_keys.empty?
      end

      # Upgrade to a V2 configuration
      def upgrade(new)
        warnings = []

        new.vm.base_mac          = self.base_mac if self.base_mac
        new.vm.box               = self.box if self.box
        new.vm.box_url           = self.box_url if self.box_url
        new.vm.guest             = self.guest if self.guest
        new.vm.hostname          = self.host_name if self.host_name
        new.vm.usable_port_range = self.auto_port_range if self.auto_port_range

        if self.boot_mode
          new.vm.provider :virtualbox do |vb|
            # Enable the GUI if the boot mode is GUI.
            vb.gui = (self.boot_mode.to_s == "gui")
          end
        end

        # If we have VM customizations, then we enable them on the
        # VirtualBox provider on the new VM.
        if !self.customizations.empty?
          warnings << "`config.vm.customize` calls are VirtualBox-specific. If you're\n" +
            "using any other provider, you'll have to use config.vm.provider in a\n" +
            "v2 configuration block."

          new.vm.provider :virtualbox do |vb|
            self.customizations.each do |customization|
              vb.customize(customization)
            end
          end
        end

        # Re-define all networks.
        self.networks.each do |type, args|
          if type == :unknown
            warnings << "Unknown network type '#{args}' will be ignored."
            next
          end

          options = {}
          options = args.pop.dup if args.last.is_a?(Hash)

          # Determine the extra options we need to set for each type
          if type == :forwarded_port
            options[:guest] = args[0]
            options[:host]  = args[1]
          elsif type == :private_network
            options[:ip] = args[0]
          end

          new.vm.network(type, options)
        end

        # Provisioners
        self.provisioners.each do |name, options, block|
          options ||= {}
          new.vm.provision(name, **options, &block)
        end

        # Shared folders
        self.shared_folders.each do |name, sf|
          options      = sf.dup
          options[:id] = name
          guestpath    = options.delete(:guestpath)
          hostpath     = options.delete(:hostpath)

          # This was the name of the old default /vagrant shared folder.
          # We warn the use that this changed, but also silently change
          # it to try to make things work properly.
          if options[:id] == "v-root"
            warnings << "The 'v-root' shared folders have been renamed to 'vagrant-root'.\n" +
              "Assuming you meant 'vagrant-root'..."

            options[:id] = "vagrant-root"
          end

          new.vm.synced_folder(hostpath, guestpath, options)
        end

        # Defined sub-VMs
        @define_calls.each do |name, options, block|
          new.vm.define(name, options, &block)
        end

        # If name is used, warn that it has no effect anymore
        if @name
          warnings << "`config.vm.name` has no effect anymore. Names are derived\n" +
            "directly from any `config.vm.define` calls."
        end

        [warnings, []]
      end
    end
  end
end
