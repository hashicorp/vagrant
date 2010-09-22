module Vagrant
  class Config
    class VagrantConfig < Base
      configures :vagrant

      attr_accessor :dotfile_name
      attr_accessor :home
      attr_accessor :host

      def initialize
        @home = nil
      end

      def validate(errors)
        [:dotfile_name, :home, :host].each do |field|
          errors.add(I18n.t("vagrant.config.common.error_empty", :field => field)) if !instance_variable_get("@#{field}".to_sym)
        end
      end
    end
  end
end
