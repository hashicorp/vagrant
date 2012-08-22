require "vagrant"

module VagrantPlugins
  module Kernel_V1
    class SSHConfig < Vagrant.plugin("1", :config)
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

      def validate(env, errors)
        [:username, :host, :max_tries, :timeout].each do |field|
          value = instance_variable_get("@#{field}".to_sym)
          errors.add(I18n.t("vagrant.config.common.error_empty", :field => field)) if !value
        end

        if private_key_path && !File.file?(File.expand_path(private_key_path, env.root_path))
          errors.add(I18n.t("vagrant.config.ssh.private_key_missing", :path => private_key_path))
        end
      end
    end
  end
end
