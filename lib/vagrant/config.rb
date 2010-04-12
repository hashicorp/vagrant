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

      def execute!
        run_procs!(config)
        config.loaded!
        config
      end
    end
  end

  class Config
    class Base
      attr_accessor :env

      def [](key)
        send(key)
      end

      def to_json
        instance_variables_hash.to_json
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

      attr_accessor :box
      attr_accessor :box_ovf
      attr_accessor :base_mac
      attr_accessor :boot_mode
      attr_accessor :project_directory
      attr_reader :forwarded_ports
      attr_reader :shared_folders
      attr_accessor :hd_location
      attr_accessor :disk_image_format
      attr_accessor :provisioner
      attr_accessor :shared_folder_uid
      attr_accessor :shared_folder_gid

      def initialize
        @forwarded_ports = {}
        @shared_folders = {}
        @provisioner = nil
      end

      def forward_port(name, guestport, hostport, protocol="TCP")
        forwarded_ports[name] = {
          :guestport  => guestport,
          :hostport   => hostport,
          :protocol   => protocol
        }
      end

      def share_folder(name, guestpath, hostpath)
        @shared_folders[name] = {
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

      class <<self
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
