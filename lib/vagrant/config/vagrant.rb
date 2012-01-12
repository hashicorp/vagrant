module Vagrant
  module Config
    class VagrantConfig < Base
      attr_accessor :dotfile_name
      attr_accessor :host

      def validate(env, errors)
        [:dotfile_name, :host].each do |field|
          errors.add(I18n.t("vagrant.config.common.error_empty", :field => field)) if !instance_variable_get("@#{field}".to_sym)
        end
      end
    end
  end
end
