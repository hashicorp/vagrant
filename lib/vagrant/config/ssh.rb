module Vagrant
  module Config
    class SSHConfig < Base
      configures :ssh

      attr_accessor :username
      attr_accessor :host
      attr_accessor :forwarded_port_key
      attr_accessor :forwarded_port_destination
      attr_accessor :max_tries
      attr_accessor :timeout
      attr_accessor :private_key_path
      attr_accessor :forward_agent
      attr_accessor :forward_x11
      attr_accessor :shell
      attr_accessor :port

      def initialize
        @shell = "bash"
        @port = nil
        @forward_agent = false
        @forward_x11 = false
        @private_key_path = nil
      end

      def validate(env, errors)
        [:username, :host, :forwarded_port_key, :max_tries, :timeout].each do |field|
          errors.add(I18n.t("vagrant.config.common.error_empty", :field => field)) if !instance_variable_get("@#{field}".to_sym)
        end

        if private_key_path && !File.file?(private_key_path)
          errors.add(I18n.t("vagrant.config.ssh.private_key_missing", :path => private_key_path))
        end
      end
    end
  end
end
