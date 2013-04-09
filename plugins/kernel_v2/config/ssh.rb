require "vagrant"

require_relative "ssh_connect"

module VagrantPlugins
  module Kernel_V2
    class SSHConfig < SSHConnectConfig
      attr_accessor :forward_agent
      attr_accessor :forward_x11
      attr_accessor :guest_port
      attr_accessor :keep_alive
      attr_accessor :max_tries
      attr_accessor :shell
      attr_accessor :timeout

      attr_reader :default

      def initialize
        super

        @forward_agent    = UNSET_VALUE
        @forward_x11      = UNSET_VALUE
        @guest_port = UNSET_VALUE
        @keep_alive = UNSET_VALUE
        @max_tries  = UNSET_VALUE
        @shell      = UNSET_VALUE
        @timeout    = UNSET_VALUE

        @default    = SSHConnectConfig.new
      end

      def merge(other)
        super.tap do |result|
          merged_defaults = @default.merge(other.default)
          result.instance_variable_set(:@default, merged_defaults)
        end
      end

      def finalize!
        super

        @forward_agent = false if @forward_agent == UNSET_VALUE
        @forward_x11   = false if @forward_x11 == UNSET_VALUE
        @guest_port = nil if @guest_port == UNSET_VALUE
        @keep_alive = false if @keep_alive == UNSET_VALUE
        @max_tries  = nil if @max_tries == UNSET_VALUE
        @shell      = nil if @shell == UNSET_VALUE
        @timeout    = nil if @timeout == UNSET_VALUE

        @default.finalize!
      end

      def to_s
        "SSH"
      end

      def validate(machine)
        errors = super

        [:max_tries, :timeout].each do |field|
          value = instance_variable_get("@#{field}".to_sym)
          errors << I18n.t("vagrant.config.common.error_empty", :field => field) if !value
        end

        # Return the errors
        result = { to_s => errors }

        # Figure out the errors for the defaults
        default_errors = @default.validate(machine)
        result["SSH Defaults"] = default_errors if !default_errors.empty?

        result
      end
    end
  end
end
