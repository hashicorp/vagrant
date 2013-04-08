require "vagrant"

module VagrantPlugins
  module Kernel_V2
    class SSHConfig < Vagrant.plugin("2", :config)
      attr_accessor :forward_agent
      attr_accessor :forward_x11
      attr_accessor :guest_port
      attr_accessor :host
      attr_accessor :keep_alive
      attr_accessor :max_tries
      attr_accessor :port
      attr_accessor :private_key_path
      attr_accessor :shell
      attr_accessor :timeout
      attr_accessor :username

      def initialize
        @forward_agent    = UNSET_VALUE
        @forward_x11      = UNSET_VALUE
        @guest_port       = UNSET_VALUE
        @host             = UNSET_VALUE
        @keep_alive       = UNSET_VALUE
        @max_tries        = UNSET_VALUE
        @port             = UNSET_VALUE
        @private_key_path = UNSET_VALUE
        @shell            = UNSET_VALUE
        @timeout          = UNSET_VALUE
        @username         = UNSET_VALUE
      end

      def finalize!
        @forward_agent    = false if @forward_agent == UNSET_VALUE
        @forward_x11      = false if @forward_x11 == UNSET_VALUE
        @guest_port       = nil if @guest_port == UNSET_VALUE
        @host             = nil if @host == UNSET_VALUE
        @keep_alive       = false if @keep_alive == UNSET_VALUE
        @max_tries        = nil if @max_tries == UNSET_VALUE
        @port             = nil if @port == UNSET_VALUE
        @private_key_path = nil if @private_key_path == UNSET_VALUE
        @shell            = nil if @shell == UNSET_VALUE
        @timeout          = nil if @timeout == UNSET_VALUE
        @username         = nil if @username == UNSET_VALUE
      end

      def to_s
        "SSH"
      end

      def validate(machine)
        errors = _detected_errors

        [:max_tries, :timeout].each do |field|
          value = instance_variable_get("@#{field}".to_sym)
          errors << I18n.t("vagrant.config.common.error_empty", :field => field) if !value
        end

        if private_key_path && \
          !File.file?(File.expand_path(private_key_path, machine.env.root_path))
          errors << I18n.t("vagrant.config.ssh.private_key_missing", :path => private_key_path)
        end

        # Return the errors
        { to_s => errors }
      end
    end
  end
end
