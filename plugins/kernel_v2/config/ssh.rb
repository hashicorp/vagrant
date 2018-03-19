require "vagrant"

require_relative "ssh_connect"

module VagrantPlugins
  module Kernel_V2
    class SSHConfig < SSHConnectConfig
      attr_accessor :forward_agent
      attr_accessor :forward_x11
      attr_accessor :forward_env
      attr_accessor :guest_port
      attr_accessor :keep_alive
      attr_accessor :shell
      attr_accessor :proxy_command
      attr_accessor :ssh_command
      attr_accessor :pty
      attr_accessor :sudo_command
      attr_accessor :export_command_template

      attr_reader :default

      def initialize
        super

        @forward_agent           = UNSET_VALUE
        @forward_x11             = UNSET_VALUE
        @forward_env             = UNSET_VALUE
        @guest_port              = UNSET_VALUE
        @keep_alive              = UNSET_VALUE
        @proxy_command           = UNSET_VALUE
        @ssh_command             = UNSET_VALUE
        @pty                     = UNSET_VALUE
        @shell                   = UNSET_VALUE
        @sudo_command            = UNSET_VALUE
        @export_command_template = UNSET_VALUE
        @default                 = SSHConnectConfig.new
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
        @forward_env   = false if @forward_env == UNSET_VALUE
        @guest_port = 22 if @guest_port == UNSET_VALUE
        @keep_alive = true if @keep_alive == UNSET_VALUE
        @proxy_command = nil if @proxy_command == UNSET_VALUE
        @ssh_command = nil if @ssh_command == UNSET_VALUE
        @pty        = false if @pty == UNSET_VALUE
        @shell      = "bash -l" if @shell == UNSET_VALUE

        if @export_command_template == UNSET_VALUE
          @export_command_template = 'export %ENV_KEY%="%ENV_VALUE%"'
        end

        if @sudo_command == UNSET_VALUE
          @sudo_command = "sudo -E -H %c"
        end

        @default.username = "vagrant" if @default.username == UNSET_VALUE
        @default.port     = @guest_port if @default.port == UNSET_VALUE
        @default.finalize!
      end

      def to_s
        "SSH"
      end

      def validate(machine)
        errors = super

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
