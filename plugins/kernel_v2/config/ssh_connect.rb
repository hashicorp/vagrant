module VagrantPlugins
  module Kernel_V2
    class SSHConnectConfig < Vagrant.plugin("2", :config)
      attr_accessor :host
      attr_accessor :port
      attr_accessor :private_key_path
      attr_accessor :username

      def initialize
        @host             = UNSET_VALUE
        @port             = UNSET_VALUE
        @private_key_path = UNSET_VALUE
        @username         = UNSET_VALUE
      end

      def finalize!
        @host             = nil if @host == UNSET_VALUE
        @port             = nil if @port == UNSET_VALUE
        @private_key_path = nil if @private_key_path == UNSET_VALUE
        @username         = nil if @username == UNSET_VALUE
      end

      # NOTE: This is _not_ a valid config validation method, since it
      # returns an _array_ of strings rather than a Hash. This is meant to
      # be used with a subclass that handles this.
      #
      # @return [Array<String>]
      def validate(machine)
        errors = _detected_errors

        if @private_key_path && \
          !File.file?(File.expand_path(@private_key_path, machine.env.root_path))
          errors << I18n.t("vagrant.config.ssh.private_key_missing", :path => @private_key_path)
        end

        errors
      end
    end
  end
end
