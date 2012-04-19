require "vagrant"

module VagrantPlugins
  module Kernel
    class SSHConfig < Vagrant::Config::V1::Base
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

      def initialize
        @username         = UNSET_VALUE
        @password         = UNSET_VALUE
        @host             = UNSET_VALUE
        @port             = UNSET_VALUE
        @guest_port       = UNSET_VALUE
        @max_tries        = UNSET_VALUE
        @timeout          = UNSET_VALUE
        @private_key_path = UNSET_VALUE
        @forward_agent    = UNSET_VALUE
        @forward_x11      = UNSET_VALUE
        @shell            = UNSET_VALUE
      end

      def validate(env, errors)
        [:username, :host, :max_tries, :timeout].each do |field|
          value = instance_variable_get("@#{field}".to_sym)
          if value == UNSET_VALUE || !value
            errors.add(I18n.t("vagrant.config.common.error_empty", :field => field))
          end
        end

        if private_key_path && private_key_path != UNSET_VALUE && !File.file?(File.expand_path(private_key_path, env.root_path))
          errors.add(I18n.t("vagrant.config.ssh.private_key_missing", :path => private_key_path))
        end
      end
    end
  end
end
