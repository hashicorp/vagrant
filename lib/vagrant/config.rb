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
      attr_accessor :password
      attr_accessor :host
      attr_accessor :port
      attr_accessor :forwarded_port_key
      attr_accessor :max_tries
      attr_accessor :timeout
      attr_accessor :private_key_path

      def private_key_path
        File.expand_path(@private_key_path, env.root_path)
      end
    end

    class VMConfig < Base
      include Util::StackedProcRunner

      attr_accessor :auto_port_range
      attr_accessor :box
      attr_accessor :box_ovf
      attr_accessor :base_mac
      attr_accessor :boot_mode
      attr_accessor :project_directory
      attr_accessor :rsync_project_directory
      attr_accessor :rsync_opts
      attr_accessor :rsync_script
      attr_accessor :rsync_crontab_entry_file
      attr_reader :rsync_required
      attr_reader :forwarded_ports
      attr_reader :shared_folders
      attr_accessor :hd_location
      attr_accessor :disk_image_format
      attr_accessor :provisioner
      attr_accessor :shared_folder_uid
      attr_accessor :shared_folder_gid
      attr_accessor :system

      def initialize
        @forwarded_ports = {}
        @shared_folders = {}
        @provisioner = nil
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

      def share_folder(name, guestpath, hostpath = nil, opts = {})
        guestpath, opts[:rsync] = shift(guestpath, opts[:rsync])

        # TODO if both are nil the exception information will be unusable
        if opts[:rsync] == guestpath
          raise Exception.new("The rsync directory #{opts[:rsync]} is identical to the shifted shared folder mount point #{guestpath}")
        end

        @shared_folders[name] = {
          :rsyncpath => opts[:rsync],
          :guestpath => guestpath,
          :hostpath => hostpath
        }
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

      def define(name, &block)
        defined_vms[name.to_sym] = block
      end

      def shift(orig, rsync)
        if rsync
          @rsync_required = true
          [orig + '-rsync', rsync == true ? orig : rsync]
        else
          [orig, rsync]
        end
      end
    end

    class PackageConfig < Base
      attr_accessor :name
      attr_accessor :extension
    end

    class VagrantConfig < Base
      attr_accessor :dotfile_name
      attr_accessor :log_output
      attr_accessor :home

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
      configures :ssh, SSHConfig
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
    end
  end
end
