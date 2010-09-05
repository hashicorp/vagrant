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

      def private_key_path
        File.expand_path(@private_key_path, env.root_path)
      end

      def validate(errors)
        [:username, :host, :port, :forwarded_port_key, :max_tries, :timeout, :private_key_path].each do |field|
          errors.add("vagrant.config.common.error_empty", :field => field) if !instance_variable_get("@#{field}".to_sym)
        end

        errors.add("vagrant.config.ssh.private_key_missing", :path => private_key_path) if !File.file?(private_key_path)
      end
    end
  end
end
