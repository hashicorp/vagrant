# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

module VagrantPlugins
  module Kernel_V2
    class SSHConnectConfig < Vagrant.plugin("2", :config)
      DEFAULT_SSH_CONNECT_RETRIES = 5
      DEFAULT_SSH_CONNECT_RETRY_DELAY = 2
      DEFAULT_SSH_CONNECT_TIMEOUT = 15

      attr_accessor :host
      attr_accessor :port
      attr_accessor :config
      attr_accessor :connect_retries
      attr_accessor :connect_retry_delay
      attr_accessor :connect_timeout
      attr_accessor :private_key_path
      attr_accessor :username
      attr_accessor :password
      attr_accessor :insert_key
      attr_accessor :keys_only
      attr_accessor :key_type
      attr_accessor :paranoid
      attr_accessor :verify_host_key
      attr_accessor :compression
      attr_accessor :dsa_authentication
      attr_accessor :extra_args
      attr_accessor :remote_user
      attr_accessor :disable_deprecated_algorithms

      def initialize
        @host             = UNSET_VALUE
        @port             = UNSET_VALUE
        @config           = UNSET_VALUE
        @connect_retries  = UNSET_VALUE
        @connect_retry_delay = UNSET_VALUE
        @connect_timeout  = UNSET_VALUE
        @private_key_path = UNSET_VALUE
        @username         = UNSET_VALUE
        @password         = UNSET_VALUE
        @insert_key       = UNSET_VALUE
        @keys_only        = UNSET_VALUE
        @key_type         = UNSET_VALUE
        @paranoid         = UNSET_VALUE
        @verify_host_key  = UNSET_VALUE
        @compression      = UNSET_VALUE
        @dsa_authentication = UNSET_VALUE
        @extra_args       = UNSET_VALUE
        @remote_user      = UNSET_VALUE
        @disable_deprecated_algorithms = UNSET_VALUE
      end

      def finalize!
        @host             = nil if @host == UNSET_VALUE
        @port             = nil if @port == UNSET_VALUE
        @private_key_path = nil if @private_key_path == UNSET_VALUE
        @username         = nil if @username == UNSET_VALUE
        @password         = nil if @password == UNSET_VALUE
        @insert_key       = true if @insert_key == UNSET_VALUE
        @keys_only        = true if @keys_only == UNSET_VALUE
        @key_type         = :auto if @key_type == UNSET_VALUE
        @paranoid         = false if @paranoid == UNSET_VALUE
        @verify_host_key  = :never if @verify_host_key == UNSET_VALUE
        @compression      = true if @compression == UNSET_VALUE
        @dsa_authentication = true if @dsa_authentication == UNSET_VALUE
        @extra_args       = nil if @extra_args == UNSET_VALUE
        @config           = nil if @config == UNSET_VALUE
        @disable_deprecated_algorithms = false if @disable_deprecated_algorithms == UNSET_VALUE
        @connect_timeout  = DEFAULT_SSH_CONNECT_TIMEOUT if @connect_timeout == UNSET_VALUE
        @connect_retries  = DEFAULT_SSH_CONNECT_RETRIES if @connect_retries == UNSET_VALUE
        @connect_retry_delay = DEFAULT_SSH_CONNECT_RETRY_DELAY if @connect_retry_delay == UNSET_VALUE

        if @private_key_path && !@private_key_path.is_a?(Array)
          @private_key_path = [@private_key_path]
        end

        if @remote_user == UNSET_VALUE
          if @username
            @remote_user = @username
          else
            @remote_user = nil
          end
        end

        if @paranoid
          @verify_host_key = @paranoid
        end

        # Values for verify_host_key changed in 5.0.0 of net-ssh. If old value
        # detected, update with new value
        case @verify_host_key
        when true
          @verify_host_key = :accepts_new_or_local_tunnel
        when false
          @verify_host_key = :never
        when :very
          @verify_host_key = :accept_new
        when :secure
          @verify_host_key = :always
        end

        # Attempt to convert timeout to integer value
        # If we can't convert the connect timeout into an integer or
        # if the value is less than 1, set it to the default value
        begin
          @connect_timeout = @connect_timeout.to_i
        rescue
          # ignore
        end

        if @key_type
          @key_type = @key_type.to_sym
        end
      end

      # NOTE: This is _not_ a valid config validation method, since it
      # returns an _array_ of strings rather than a Hash. This is meant to
      # be used with a subclass that handles this.
      #
      # @return [Array<String>]
      def validate(machine)
        errors = _detected_errors

        if @private_key_path
          @private_key_path.each do |raw_path|
            path = File.expand_path(raw_path, machine.env.root_path)
            if !File.file?(path)
              errors << I18n.t(
                "vagrant.config.ssh.private_key_missing",
                path: raw_path)
            end
          end
        end

        if @config
          config_path = File.expand_path(@config, machine.env.root_path)
          if !File.file?(config_path)
            errors << I18n.t(
              "vagrant.config.ssh.ssh_config_missing",
              path: @config)
          end
        end

        if @paranoid
          machine.env.ui.warn(I18n.t("vagrant.config.ssh.paranoid_deprecated"))
        end

        if !@connect_timeout.is_a?(Integer)
          errors << I18n.t(
            "vagrant.config.ssh.connect_timeout_invalid_type",
            given: @connect_timeout.class.name)
        elsif @connect_timeout < 1
          errors << I18n.t(
            "vagrant.config.ssh.connect_timeout_invalid_value",
            given: @connect_timeout.to_s)
        end

        if !@connect_retries.is_a?(Integer)
          errors << I18n.t(
            "vagrant.config.ssh.connect_retries_invalid_type",
            given: @connect_retries.class.name
          )
        elsif @connect_retries < 0
          errors << I18n.t(
            "vagrant.config.ssh.connect_retries_invalid_value",
            given: @connect_retries.to_s
          )
        end

        if !@connect_retry_delay.is_a?(Numeric)
          errors << I18n.t(
            "vagrant.config.ssh.connect_retry_delay_invalid_type",
            given: @connect_retry_delay.class.name
          )
        elsif @connect_retry_delay < 0
          errors << I18n.t(
            "vagrant.config.ssh.connect_retry_delay_invalid_value",
            given: @connect_retry_delay.to_s
          )
        end

        if @key_type != :auto && !Vagrant::Util::Keypair.valid_type?(@key_type)
          errors << I18n.t(
            "vagrant.config.ssh.connect_invalid_key_type",
            given: @key_type.to_s,
            supported: Vagrant::Util::Keypair.available_types.join(", ")
          )
        end

        errors
      end
    end
  end
end
