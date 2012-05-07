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

      def private_key_path=(value)
        if @private_key_path.nil? then
          @private_key_path = []
        end
        if value.kind_of?(String) then
          value = [value]
        end
        @private_key_path.concat(value)
      end

      def validate(env, errors)
        [:username, :host, :max_tries, :timeout].each do |field|
          value = instance_variable_get("@#{field}".to_sym)
          errors.add(I18n.t("vagrant.config.common.error_empty", :field => field)) if !value
        end

        if private_key_path then
          unless private_key_path.kind_of?(Array) then
            errors.add(I18n.t("vagrant.config.ssh.private_key_invalid_format", :klass => private_key_path.class.to_s))
          end
          private_key_path.each do |path|
            if !File.file?(File.expand_path(path, env.root_path)) then
              errors.add(I18n.t("vagrant.config.ssh.private_key_missing", :path => private_key_path))
            end
          end
        end
      end
    end
  end
end
