module Vagrant
  def self.config
    Config.config
  end

  class Config
    @config = nil
    @config_runners = []

    class << self
      def config
        @config ||= Config::Top.new
      end

      def config_runners
        @config_runners ||= []
      end

      def run(&block)
        config_runners << block
      end

      def execute!
        config_runners.each do |block|
          block.call(config)
        end
      end
    end
  end

  class Config
    class Base
      def [](key)
        send(key)
      end
    end

    class SSHConfig < Base
      attr_accessor :username
      attr_accessor :password
      attr_accessor :host
      attr_accessor :forwarded_port_key
      attr_accessor :max_tries
    end

    class VMConfig < Base
      attr_accessor :base
      attr_accessor :base_mac
      attr_accessor :project_directory
      attr_reader :forwarded_ports
      attr_accessor :hd_location

      def initialize
        @forwarded_ports = {}
      end

      def forward_port(name, guestport, hostport, protocol="TCP")
        forwarded_ports[name] = {
          :guestport  => guestport,
          :hostport   => hostport,
          :protocol   => protocol
        }
      end

      def hd_location=(val)
        raise Exception.new "disk_storage must be set to a directory" unless File.directory?(val)
        @hd_location=val
      end
    end

    class ChefConfig < Base
      attr_accessor :cookbooks_path
      attr_accessor :provisioning_path
      attr_accessor :json
    end

    class Top < Base
      attr_accessor :dotfile_name
      attr_reader :ssh
      attr_reader :vm
      attr_reader :chef

      def initialize
        @ssh = SSHConfig.new
        @vm = VMConfig.new
        @chef = ChefConfig.new
      end
    end
  end
end
