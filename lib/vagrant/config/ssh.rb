module Vagrant
  module Config
    class SSHConfig < Base
      attr_accessor :username
      attr_accessor :password
      attr_accessor :host
      attr_accessor :port
      attr_accessor :guest_port
      attr_accessor :max_tries
      attr_accessor :timeout
      attr_accessor :private_key_path
      attr_accessor :forward_agent
      attr_accessor :forward_x11
      attr_accessor :shell

      def forwarded_port_key=(value)
        raise Errors::DeprecationError, :message => <<-MESSAGE
`config.ssh.forwarded_port_key` is now gone. You must now use
`config.ssh.guest_port` which is expected to be the port on the
guest that SSH is listening on. Vagrant will automatically scan
the forwarded ports to look for a forwarded port from this port
and use it.
        MESSAGE
      end

      def forwarded_port_destination=(value)
        raise Errors::DeprecationError, :message => <<-MESSAGE
`config.ssh.forwarded_port_destination` is now gone. You must now use
`config.ssh.guest_port` which is expected to be the port on the
guest that SSH is listening on. Vagrant will automatically scan
the forwarded ports to look for a forwarded port from this port
and use it.
        MESSAGE
      end

      def validate(env, errors)
        [:username, :host, :max_tries, :timeout].each do |field|
          errors.add(I18n.t("vagrant.config.common.error_empty", :field => field)) if !instance_variable_get("@#{field}".to_sym)
        end

        if private_key_path && !File.file?(private_key_path)
          errors.add(I18n.t("vagrant.config.ssh.private_key_missing", :path => private_key_path))
        end
      end
    end
  end
end
