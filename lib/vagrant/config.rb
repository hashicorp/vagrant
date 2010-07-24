module Vagrant
  def self.config
    Config.config
  end

  class Config
    extend Util::StackedProcRunner

    @@config = nil

    class << self
      def reset!(env=nil)
        @@config = nil
        proc_stack.clear

        # Reset the configuration to the specified environment
        config(env)
      end

      def configures(key, klass)
        config.class.configures(key, klass)
      end

      def config(env=nil)
        @@config ||= Config::Top.new(env)
      end

      def run(&block)
        push_proc(&block)
      end

      def execute!(config_object=nil)
        config_object ||= config

        run_procs!(config_object)
        config_object.loaded!
        config_object
      end
    end
  end

  class Config
    class Base
      attr_accessor :env

      def [](key)
        send(key)
      end

      def to_json(*a)
        instance_variables_hash.to_json(*a)
      end

      def instance_variables_hash
        instance_variables.inject({}) do |acc, iv|
          acc[iv.to_s[1..-1].to_sym] = instance_variable_get(iv) unless iv.to_sym == :@env
          acc
        end
      end
    end

    class SSHConfig < Base
      attr_accessor :username
      attr_accessor :host
      attr_accessor :port
      attr_accessor :forwarded_port_key
      attr_accessor :max_tries
      attr_accessor :timeout
      attr_accessor :private_key_path
      attr_accessor :forward_agent

      # The attribute(s) below do nothing. They are just kept here to
      # prevent syntax errors for backwards compat.
      attr_accessor :password

      def private_key_path
        File.expand_path(@private_key_path, env.root_path)
      end
    end

    class UnisonConfig < Base
      attr_accessor :folder_suffix
      attr_accessor :script
      attr_accessor :options
      attr_accessor :crontab_entry_file
      attr_accessor :log_file
    end

    class NFSConfig < Base
      attr_accessor :map_uid
      attr_accessor :map_gid
    end

    class VMConfig < Base
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
      attr_accessor :hd_location
      attr_accessor :disk_image_format
      attr_accessor :provisioner
      attr_accessor :shared_folder_uid
      attr_accessor :shared_folder_gid
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

      def hd_location=(val)
        raise Exception.new("disk_storage must be set to a directory") unless File.directory?(val)
        @hd_location=val
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

      def define(name, options=nil, &block)
        options ||= {}
        defined_vms[name.to_sym] ||= SubVM.new
        defined_vms[name.to_sym].options.merge!(options)
        defined_vms[name.to_sym].push_proc(&block)
      end
    end

    class PackageConfig < Base
      attr_accessor :name
    end

    class VagrantConfig < Base
      attr_accessor :dotfile_name
      attr_accessor :log_output
      attr_accessor :home
      attr_accessor :host

      def home
        @home ? File.expand_path(@home) : nil
      end
    end

    class Top < Base
      @@configures = []

      class << self
        def configures_list
          @@configures ||= []
        end

        def configures(key, klass)
          configures_list << [key, klass]
          attr_reader key.to_sym
        end
      end

      # Setup default configures
      configures :package, PackageConfig
      configures :nfs, NFSConfig
      configures :ssh, SSHConfig
      configures :unison, UnisonConfig
      configures :vm, VMConfig
      configures :vagrant, VagrantConfig

      def initialize(env=nil)
        self.class.configures_list.each do |key, klass|
          config = klass.new
          config.env = env
          instance_variable_set("@#{key}".to_sym, config)
        end

        @loaded = false
        @env = env
      end

      def loaded?
        @loaded
      end

      def loaded!
        @loaded = true
      end

      # Deep clones the entire configuration tree using the marshalling
      # trick. All subclasses must be able to marshal properly.
      def deep_clone
        Marshal.load(Marshal.dump(self))
      end
    end
  end
end
