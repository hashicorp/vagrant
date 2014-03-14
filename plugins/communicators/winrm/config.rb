module VagrantPlugins
  module CommunicatorWinRM
    class Config < Vagrant.plugin("2", :config)
      attr_accessor :username
      attr_accessor :password
      attr_accessor :host
      attr_accessor :port
      attr_accessor :guest_port
      attr_accessor :max_tries
      attr_accessor :timeout

      def initialize
        @username   = UNSET_VALUE
        @password   = UNSET_VALUE
        @host       = UNSET_VALUE
        @port       = UNSET_VALUE
        @guest_port = UNSET_VALUE
        @max_tries  = UNSET_VALUE
        @timeout    = UNSET_VALUE
      end

      def finalize!
        @username = "vagrant" if @username == UNSET_VALUE
        @password = "vagrant" if @password == UNSET_VALUE
        @host = nil           if @host == UNSET_VALUE
        @port = 5985          if @port == UNSET_VALUE
        @guest_port = 5985    if @guest_port == UNSET_VALUE
        @max_tries = 20       if @max_tries == UNSET_VALUE
        @timeout = 1800       if @timeout == UNSET_VALUE
      end

      def validate(machine)
        errors = []

        errors << "winrm.username cannot be nil."   if @username.nil?
        errors << "winrm.password cannot be nil."   if @password.nil?
        errors << "winrm.port cannot be nil."       if @port.nil?
        errors << "winrm.guest_port cannot be nil." if @guest_port.nil?
        errors << "winrm.max_tries cannot be nil."  if @max_tries.nil?
        errors << "winrm.timeout cannot be nil."    if @timeout.nil?

        { "WinRM" => errors }
      end
    end
  end
end
