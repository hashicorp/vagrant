require "vagrant"
require_relative "host_share/config"

module VagrantPlugins
  module HyperV
    class Config < Vagrant.plugin("2", :config)
      # The timeout to wait for an IP address when booting the machine,
      # in seconds.
      #
      # @return [Integer]
      attr_accessor :ip_address_timeout

      attr_reader :host_share

      def initialize
        @ip_address_timeout = UNSET_VALUE
        @host_share = HostShare::Config.new
      end

      def host_config(&block)
        block.call(@host_share)
      end

      def finalize!
        if @ip_address_timeout == UNSET_VALUE
          @ip_address_timeout = 120
        end
      end


      def validate(machine)
        errors = _detected_errors
=begin
        unless host_share.valid_config?
          errors << host_share.errors.flatten.join(" ")
        end
=end
        { "HyperV" => errors }
      end
    end
  end
end
