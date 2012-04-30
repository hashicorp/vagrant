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
      attr_accessor :private_key_paths
      attr_accessor :forward_agent
      attr_accessor :forward_x11
      attr_accessor :shell

      def private_key_path=(path)
        if self.private_key_paths.nil? then
          self.private_key_paths = []
        end
        self.private_key_paths << path
      end

      def validate(env, errors)
        [:username, :host, :max_tries, :timeout].each do |field|
          errors.add(I18n.t("vagrant.config.common.error_empty", :field => field)) if !instance_variable_get("@#{field}".to_sym)
        end

        if private_key_paths then
          private_key_paths.each do |private_key_path|
            if !File.file?(File.expand_path(private_key_path, env.root_path)) then
              errors.add(I18n.t("vagrant.config.ssh.private_key_missing", :path => private_key_path))
            end
          end
        end
      end
    end
  end
end
