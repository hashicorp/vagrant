module Vagrant
  def self.config
    Config.config
  end

  class Config
    @@config = nil
    @@config_runners = []

    class << self
      def reset!
        @@config = nil
        config_runners.clear
      end

      def configures(key, klass)
        @@config.class.configures(key, klass)
      end

      def config
        @@config ||= Config::Top.new
      end

      def config_runners
        @@config_runners ||= []
      end

      def run(&block)
        config_runners << block
      end

      def execute!
        config_runners.each do |block|
          block.call(config)
        end

        config.loaded!
      end
    end
  end

  class Config
    class Base
      def [](key)
        send(key)
      end

      def to_json
        instance_variables_hash.to_json
      end

      def instance_variables_hash
        instance_variables.inject({}) do |acc, iv|
          acc[iv.to_s[1..-1].to_sym] = instance_variable_get(iv)
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
    end

    class VMConfig < Base
      attr_accessor :box
      attr_accessor :box_ovf
      attr_accessor :base_mac
      attr_accessor :project_directory
      attr_reader :forwarded_ports
      attr_reader :shared_folders
      attr_accessor :hd_location
      attr_accessor :disk_image_format


      def initialize
        @forwarded_ports = {}
        @shared_folders = {}
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
        raise Exception.new "disk_storage must be set to a directory" unless File.directory?(val)
        @hd_location=val
      end

      def base
        File.expand_path(@base)
      end
    end

    class PackageConfig < Base
      attr_accessor :name
      attr_accessor :extension
    end

    class ChefConfig < Base
      attr_accessor :cookbooks_path
      attr_accessor :provisioning_path
      attr_accessor :json
      attr_accessor :enabled

      def initialize
        @enabled = false
      end

      def to_json
        # Overridden so that the 'json' key could be removed, since its just
        # merged into the config anyways
        data = instance_variables_hash
        data.delete(:json)
        data.to_json
      end
    end

    class VagrantConfig < Base
      attr_accessor :dotfile_name
      attr_accessor :log_output
      attr_accessor :home

      def home
        File.expand_path(@home)
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
      configures :chef, ChefConfig
      configures :vagrant, VagrantConfig

      def initialize
        self.class.configures_list.each do |key, klass|
          instance_variable_set("@#{key}".to_sym, klass.new)
        end

        @loaded = false
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
