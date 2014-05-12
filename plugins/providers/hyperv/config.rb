require "vagrant"

module VagrantPlugins
  module HyperV
    class Config < Vagrant.plugin("2", :config)
      # The timeout to wait for an IP address when booting the machine,
      # in seconds.
      #
      # @return [Integer]
      attr_accessor :ip_address_timeout
      attr_reader :customizations

      def initialize
        @ip_address_timeout = UNSET_VALUE
        @customizations   = []
      end

      def customize(*command)
        @customizations ||= []
        event   = command.first.is_a?(String) ? command.shift : "pre-boot"
        command = command[0]
        options = command[1]
        @customizations << [event, command, options]
      end

      def finalize!
        if @ip_address_timeout == UNSET_VALUE
          @ip_address_timeout = 120
        end
      end

      def validate(machine)
        errors = _detected_errors

        valid_events = ["pre-boot"]
        @customizations.each do |event, _|
          if !valid_events.include?(event)
            errors << "Invalid custom event #{event} use pre-boot"
          end
        end

        { "Hyper-V" => errors }
      end
    end
  end
end
