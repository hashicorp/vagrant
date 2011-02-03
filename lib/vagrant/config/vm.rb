require 'vagrant/config/vm/sub_vm'
require 'vagrant/config/vm/provisioner'

module Vagrant
  class Config
    class VMConfig < Base
      configures :vm

      include Util::StackedProcRunner

      attr_accessor :auto_port_range
      attr_accessor :box
      attr_accessor :box_url
      attr_accessor :box_ovf
      attr_accessor :base_mac
      attr_accessor :boot_mode
      attr_accessor :host_name
      attr_reader :forwarded_ports
      attr_reader :shared_folders
      attr_reader :network_options
      attr_reader :provisioners
      attr_accessor :disk_image_format
      attr_writer :shared_folder_uid
      attr_writer :shared_folder_gid
      attr_accessor :system

      def initialize
        @forwarded_ports = {}
        @shared_folders = {}
        @network_options = []
        @provisioners = []
      end

      def forward_port(name, guestport, hostport, options=nil)
        options = {
          :guestport  => guestport,
          :hostport   => hostport,
          :protocol   => "TCP",
          :adapter    => 0,
          :auto       => false
        }.merge(options || {})

        forwarded_ports[name] = options
      end

      def share_folder(name, guestpath, hostpath, opts=nil)
        @shared_folders[name] = {
          :guestpath => guestpath,
          :hostpath => hostpath
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
        @provisioners << Provisioner.new(top, name, options, &block)
      end

      # This shows an error message to smooth the transition for the
      # backwards incompatible provisioner syntax change introduced
      # in Vagrant 0.7.0.
      def provisioner=(_value)
        raise Errors::VagrantError, :_key => :provisioner_equals_not_supported
      end

      def shared_folder_uid
        @shared_folder_uid || env.config.ssh.username
      end

      def shared_folder_gid
        @shared_folder_gid || env.config.ssh.username
      end

      def customize(&block)
        push_proc(&block)
      end

      def has_multi_vms?
        !defined_vms.empty?
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
        defined_vms[name].push_proc(&block)
      end

      def validate(errors)
        errors.add(I18n.t("vagrant.config.vm.box_missing")) if !box
        errors.add(I18n.t("vagrant.config.vm.box_not_found", :name => box)) if box && !box_url && !env.box
        errors.add(I18n.t("vagrant.config.vm.boot_mode_invalid")) if ![:vrdp, :gui].include?(boot_mode.to_sym)
        errors.add(I18n.t("vagrant.config.vm.base_mac_invalid")) if env.box && !base_mac

        shared_folders.each do |name, options|
          if !File.directory?(File.expand_path(options[:hostpath].to_s, env.root_path))
            errors.add(I18n.t("vagrant.config.vm.shared_folder_hostpath_missing",
                       :name => name,
                       :path => options[:hostpath]))
          end
        end

        # Each provisioner can validate itself
        provisioners.each do |prov|
          prov.validate(errors)
        end
      end
    end
  end
end
