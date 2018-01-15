require "vagrant"

module VagrantPlugins
  module Kernel_V2
    class VagrantConfig < Vagrant.plugin("2", :config)
      attr_accessor :host
      attr_accessor :sensitive

      def initialize
        @host = UNSET_VALUE
        @sensitive = UNSET_VALUE
      end

      def finalize!
        @host = :detect if @host == UNSET_VALUE
        @host = @host.to_sym if @host
        @sensitive = nil if @sensitive == UNSET_VALUE

        if @sensitive.is_a?(Array) || @sensitive.is_a?(String)
          Array(@sensitive).each do |value|
            Vagrant::Util::CredentialScrubber.sensitive(value.to_s)
          end
        end
      end

      def validate(machine)
        errors = _detected_errors

        if @sensitive && (!@sensitive.is_a?(Array) && !@sensitive.is_a?(String))
          errors << I18n.t("vagrant.config.root.sensitive_bad_type")
        end
        {"vagrant" => errors}
      end

      def to_s
        "Vagrant"
      end
    end
  end
end
