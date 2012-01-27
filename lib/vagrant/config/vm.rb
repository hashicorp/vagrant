require 'pathname'

require 'vagrant/config/vm/sub_vm'
require 'vagrant/config/vm/provisioner'

module Vagrant
  module Config
    class VMConfig < Base
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

      def system=(value)
        raise Errors::DeprecationError, :message => <<-MESSAGE
`config.vm.system` has changed to `config.vm.guest` in Vagrant 0.9,
since this is more clear about the use of the configuration key.
Please change all references of `config.vm.system` to `config.vm.guest`.
        MESSAGE
      end

      def forward_port(guestport, hostport, options=nil)
        if !guestport.kind_of?(Integer)
          raise Errors::DeprecationError, :message => <<-MESSAGE
`config.vm.forward_port` changed in 0.9.0 where the required name
argument is now removed. Vagrant will now automatically generate
a unique name for your forwarded port. For example, to forward
port 80 to port 8080 you now do the following:

    config.vm.forward_port 80, 8080

Please change your configurations to match this new syntax.
          MESSAGE
        end

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
        if !type.kind_of?(Symbol)
          raise Errors::DeprecationError, :message => <<-MESSAGE
`config.vm.network` changed in 0.9.0 where the first argument is
now the type of network and the remaining arguments are options for
that type. For example, host only networks are now configured like
so:

    config.vm.network :hostonly, "172.24.24.24"

Please change your configurations to match this new syntax.
          MESSAGE
        end

        @networks << [type, args]
      end

      def provision(name, options=nil, &block)
        @provisioners << Provisioner.new(name, options, &block)
      end

      # TODO: This argument should not be `nil` in the future.
      # It is only defaulted to nil so that the deprecation error
      # can be properly shown.
      def customize(command=nil)
        if block_given?
          raise Errors::DeprecationError, :message => <<-MESSAGE
`config.vm.customize` now takes an array of arguments to send to
`VBoxManage` instead of having a block which gets a virtual machine
object. Example of the new usage:

    config.vm.customize ["modifyvm", :id, "--memory", "1024"]

The above will run `VBoxManage modifyvm 1234 --memory 1024` where
"1234" is the ID of your current virtual machine. Anything you could
do before is certainly still possible with `VBoxManage` as well.
          MESSAGE
        end

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
        defined_vms[name] ||= SubVM.new
        defined_vms[name].options.merge!(options)
        defined_vms[name].push_proc(&block) if block
      end

      def validate(env, errors)
        errors.add(I18n.t("vagrant.config.vm.box_missing")) if !box
        errors.add(I18n.t("vagrant.config.vm.box_not_found", :name => box)) if box && !box_url && !env.boxes.find(box)
        errors.add(I18n.t("vagrant.config.vm.boot_mode_invalid")) if ![:headless, :gui].include?(boot_mode.to_sym)
        errors.add(I18n.t("vagrant.config.vm.base_mac_invalid")) if env.boxes.find(box) && !base_mac

        shared_folders.each do |name, options|
          hostpath = Pathname.new(options[:hostpath]).expand_path(env.root_path)

          if !hostpath.directory? && !options[:create]
            errors.add(I18n.t("vagrant.config.vm.shared_folder_hostpath_missing",
                       :name => name,
                       :path => options[:hostpath]))
          end

          if options[:nfs] && (options[:owner] || options[:group])
            # Owner/group don't work with NFS
            errors.add(I18n.t("vagrant.config.vm.shared_folder_nfs_owner_group",
                              :name => name))
          end
        end

        # Validate some basic networking
        #
        # TODO: One day we need to abstract this out, since in the future
        # providers other than VirtualBox will not be able to satisfy
        # all types of networks.
        networks.each do |type, args|
          if type == :hostonly && args[0] == :dhcp
            # Valid. There is no real way this can be invalid at the moment.
          elsif type == :hostonly
            # Validate the host-only network
            ip      = args[0]
            options = args[1] || {}

            if !ip
              errors.add(I18n.t("vagrant.config.vm.network_ip_required"))
            else
              ip_parts = ip.split(".")

              if ip_parts.length != 4
                errors.add(I18n.t("vagrant.config.vm.network_ip_invalid",
                                  :ip => ip))
              elsif ip_parts.last == "1"
                errors.add(I18n.t("vagrant.config.vm.network_ip_ends_one",
                                  :ip => ip))
              end
            end
          elsif type == :bridged
          else
            # Invalid network type
            errors.add(I18n.t("vagrant.config.vm.network_invalid",
                              :type => type.to_s))
          end
        end

        # Each provisioner can validate itself
        provisioners.each do |prov|
          prov.validate(env, errors)
        end
      end
    end
  end
end
