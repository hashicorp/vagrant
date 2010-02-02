require 'forwardable'

module Hobo
  def self.config
    Config.config
  end

  class Config
    @config = nil
    @config_runners = []

    class <<self
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
      attr_accessor :uname
      attr_accessor :pass
      attr_accessor :host
      attr_accessor :port
      attr_accessor :max_tries
    end

    class VMConfig < Base
      attr_accessor :base
      attr_accessor :base_mac
    end

    class Top < Base
      attr_accessor :dotfile_name
      attr_reader :ssh
      attr_reader :vm

      def initialize
        @ssh = SSHConfig.new
        @vm = VMConfig.new
      end
    end
  end
end
