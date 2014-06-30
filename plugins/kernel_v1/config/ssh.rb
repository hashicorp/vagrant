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
      attr_accessor :forward_env
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
        @forward_env      = UNSET_VALUE
        @shell            = UNSET_VALUE
      end

      def upgrade(new)
        new.ssh.username         = @username if @username != UNSET_VALUE
        new.ssh.host             = @host if @host != UNSET_VALUE
        new.ssh.port             = @port if @port != UNSET_VALUE
        new.ssh.guest_port       = @guest_port if @guest_port != UNSET_VALUE
        new.ssh.private_key_path = @private_key_path if @private_key_path != UNSET_VALUE
        new.ssh.forward_agent    = @forward_agent if @forward_agent != UNSET_VALUE
        new.ssh.forward_x11      = @forward_x11 if @forward_x11 != UNSET_VALUE
        new.ssh.forward_env      = @forward_env if @forward_env != UNSET_VALUE
        new.ssh.shell            = @shell if @shell != UNSET_VALUE
      end
    end
  end
end
