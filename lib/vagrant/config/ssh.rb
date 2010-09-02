module Vagrant
  class Config
    class SSHConfig < Base
      Config.configures :ssh, self

      attr_accessor :username
      attr_accessor :host
      attr_accessor :port
      attr_accessor :forwarded_port_key
      attr_accessor :max_tries
      attr_accessor :timeout
      attr_writer :private_key_path
      attr_accessor :forward_agent

      # The attribute(s) below do nothing. They are just kept here to
      # prevent syntax errors for backwards compat.
      attr_accessor :password

      def private_key_path
        File.expand_path(@private_key_path, env.root_path)
      end
    end
  end
end
