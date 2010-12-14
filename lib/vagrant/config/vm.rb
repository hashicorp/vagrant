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
      attr_reader :forwarded_ports
      attr_reader :shared_folders
      attr_reader :network_options
      attr_reader :hd_location
      attr_accessor :disk_image_format
      attr_accessor :provisioner
      attr_writer :shared_folder_uid
      attr_writer :shared_folder_gid
      attr_accessor :system

      # Represents a SubVM. This class is only used here in the VMs
      # hash.
      class SubVM
        include Util::StackedProcRunner

        def options
          @options ||= {}
        end
      end

      def initialize
        @forwarded_ports = {}
        @shared_folders = {}
        @provisioner = nil
        @network_options = []
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
          :name => nil
        }.merge(options || {})

        @network_options[options[:adapter]] = options
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
        options ||= {}
        defined_vm_keys << name
        defined_vms[name.to_sym] ||= SubVM.new
        defined_vms[name.to_sym].options.merge!(options)
        defined_vms[name.to_sym].push_proc(&block)
      end

      def validate(errors)
        shared_folders.each do |name, options|
          if !File.directory?(File.expand_path(options[:hostpath].to_s, env.root_path))
            errors.add(I18n.t("vagrant.config.vm.shared_folder_hostpath_missing",
                       :name => name,
                       :path => options[:hostpath]))
          end
        end

        errors.add(I18n.t("vagrant.config.vm.box_missing")) if !box
        errors.add(I18n.t("vagrant.config.vm.box_not_found", :name => box)) if box && !box_url && !env.box
        errors.add(I18n.t("vagrant.config.vm.boot_mode_invalid")) if ![:vrdp, :gui].include?(boot_mode.to_sym)
        errors.add(I18n.t("vagrant.config.vm.base_mac_invalid")) if env.box && !base_mac
      end
    end
  end
end
