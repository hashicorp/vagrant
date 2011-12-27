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
      attr_reader :network_options
      attr_reader :provisioners
      attr_reader :customizations
      attr_accessor :guest

      def initialize
        @forwarded_ports = {}
        @shared_folders = {}
        @network_options = []
        @provisioners = []
        @customizations = []
      end

      def forward_port(name, guestport, hostport, options=nil)
        options = {
          :guestport  => guestport,
          :hostport   => hostport,
          :protocol   => :tcp,
          :adapter    => 0,
          :auto       => false
        }.merge(options || {})

        forwarded_ports[name.to_s] = options
      end

      def share_folder(name, guestpath, hostpath, opts=nil)
        @shared_folders[name] = {
          :guestpath => guestpath,
          :hostpath => hostpath,
          :owner => nil,
          :group => nil,
          :nfs   => false
        }.merge(opts || {})
      end

      def network(ip, options=nil)
        options = {
          :ip => ip,
          :netmask => "255.255.255.0",
          :adapter => 1,
          :mac => nil,
          :name => nil
        }.merge(options || {})

        @network_options[options[:adapter]] = options
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
          if !File.directory?(File.expand_path(options[:hostpath].to_s, env.root_path))
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
        network_options.each do |options|
          next if !options

          ip = options[:ip].split(".")

          if ip.length != 4
            errors.add(I18n.t("vagrant.config.vm.network_ip_invalid",
                              :ip => options[:ip]))
          elsif ip.last == "1"
            errors.add(I18n.t("vagrant.config.vm.network_ip_ends_one",
                              :ip => options[:ip]))
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
