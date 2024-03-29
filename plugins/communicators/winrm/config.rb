# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

module VagrantPlugins
  module CommunicatorWinRM
    class Config < Vagrant.plugin("2", :config)
      attr_accessor :username
      attr_accessor :password
      attr_accessor :host
      attr_accessor :port
      attr_accessor :guest_port
      attr_accessor :max_tries
      attr_accessor :retry_delay
      attr_accessor :timeout
      attr_accessor :transport
      attr_accessor :ssl_peer_verification
      attr_accessor :execution_time_limit
      attr_accessor :basic_auth_only
      attr_accessor :codepage

      def initialize
        @username               = UNSET_VALUE
        @password               = UNSET_VALUE
        @host                   = UNSET_VALUE
        @port                   = UNSET_VALUE
        @guest_port             = UNSET_VALUE
        @max_tries              = UNSET_VALUE
        @retry_delay            = UNSET_VALUE
        @timeout                = UNSET_VALUE
        @transport              = UNSET_VALUE
        @ssl_peer_verification  = UNSET_VALUE
        @execution_time_limit   = UNSET_VALUE
        @basic_auth_only        = UNSET_VALUE
        @codepage               = UNSET_VALUE
      end

      def finalize!
        @username = "vagrant"   if @username == UNSET_VALUE
        @password = "vagrant"   if @password == UNSET_VALUE
        @transport = :negotiate if @transport == UNSET_VALUE
        @host = nil           if @host == UNSET_VALUE
        is_ssl = @transport == :ssl
        @port = (is_ssl ? 5986 : 5985)       if @port == UNSET_VALUE
        @guest_port = (is_ssl ? 5986 : 5985) if @guest_port == UNSET_VALUE
        @max_tries = 20        if @max_tries == UNSET_VALUE
        @retry_delay = 2       if @retry_delay == UNSET_VALUE
        @timeout = 1800        if @timeout == UNSET_VALUE
        @ssl_peer_verification = true if @ssl_peer_verification == UNSET_VALUE
        @execution_time_limit = "PT2H"   if @execution_time_limit == UNSET_VALUE
        @basic_auth_only = false    if @basic_auth_only == UNSET_VALUE
        @codepage = nil        if @codepage == UNSET_VALUE
      end

      def validate(machine)
        errors = []

        errors << "winrm.username cannot be nil."    if @username.nil?
        errors << "winrm.password cannot be nil."    if @password.nil?
        errors << "winrm.port cannot be nil."        if @port.nil?
        errors << "winrm.guest_port cannot be nil."  if @guest_port.nil?
        errors << "winrm.max_tries cannot be nil."   if @max_tries.nil?
        errors << "winrm.retry_delay cannot be nil." if @retry_delay.nil?
        errors << "winrm.timeout cannot be nil."     if @timeout.nil?
        errors << "winrm.execution_time_limit cannot be nil."     if @execution_time_limit.nil?
        unless @ssl_peer_verification == true || @ssl_peer_verification == false
          errors << "winrm.ssl_peer_verification must be a boolean."
        end
        unless @basic_auth_only == true || @basic_auth_only == false
          errors << "winrm.basic_auth_only must be a boolean."
        end

        { "WinRM" => errors }
      end
    end
  end
end
