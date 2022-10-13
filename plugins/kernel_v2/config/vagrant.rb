require "vagrant"

module VagrantPlugins
  module Kernel_V2
    class VagrantConfig < Vagrant.plugin("2", :config)
      attr_accessor :host
      attr_accessor :sensitive
      attr_accessor :plugins

      VALID_PLUGIN_KEYS = ["sources", "version", "entry_point"].map(&:freeze).freeze
      INVALID_PLUGIN_FORMAT = :invalid_plugin_format

      def initialize
        @host = UNSET_VALUE
        @sensitive = UNSET_VALUE
        @plugins = UNSET_VALUE
      end

      def finalize!
        @host = :detect if @host == UNSET_VALUE
        @host = @host.to_sym if @host
        @sensitive = nil if @sensitive == UNSET_VALUE
        if @plugins == UNSET_VALUE
          @plugins = {}
        else
          @plugins = format_plugins(@plugins)
        end

        if @sensitive.is_a?(Array) || @sensitive.is_a?(String)
          Array(@sensitive).each do |value|
            Vagrant::Util::CredentialScrubber.sensitive(value.to_s)
          end
        end
      end

      # Validate the configuration
      #
      # @param [Vagrant::Machine, NilClass] machine Machine instance or nil
      # @return [Hash]
      def validate(machine)
        errors = _detected_errors

        if @sensitive && (!@sensitive.is_a?(Array) && !@sensitive.is_a?(String))
          errors << I18n.t("vagrant.config.root.sensitive_bad_type")
        end

        if @plugins == INVALID_PLUGIN_FORMAT
          errors << I18n.t("vagrant.config.root.plugins_invalid_format")
        else
          @plugins.each do |plugin_name, plugin_info|
            if plugin_info.is_a?(Hash)
              invalid_keys = plugin_info.keys - VALID_PLUGIN_KEYS
              if !invalid_keys.empty?
                errors << I18n.t("vagrant.config.root.plugins_bad_key",
                  plugin_name: plugin_name,
                  plugin_key: invalid_keys.join(", ")
                )
              end
            else
              errors << I18n.t("vagrant.config.root.plugins_invalid_format")
            end
          end
        end

        {"vagrant" => errors}
      end

      def to_s
        "Vagrant"
      end

      def format_plugins(val)
        case val
        when String
          {val => Vagrant::Util::HashWithIndifferentAccess.new}
        when Array
          val.inject(Vagrant::Util::HashWithIndifferentAccess.new) { |memo, item|
            memo.merge(format_plugins(item))
          }
        when Hash
          Vagrant::Util::HashWithIndifferentAccess.new.tap { |h|
            val.each_pair { |k, v|
              if v.is_a?(Hash)
                h[k] = Vagrant::Util::HashWithIndifferentAccess.new(v)
              else
                h[k] = v
              end
            }
          }
        else
          INVALID_PLUGIN_FORMAT
        end
      end
    end
  end
end
