module Vagrant
  class Config
    class VagrantConfig < Base
      configures :vagrant

      attr_accessor :dotfile_name
      attr_accessor :log_output
      attr_writer :home
      attr_accessor :host

      def initialize
        @home = nil
      end

      def home
        File.expand_path(@home)
      end

      def validate(errors)
        [:dotfile_name, :home, :host].each do |field|
          errors.add("vagrant.config.common.error_empty", :field => field) if !instance_variable_get("@#{field}".to_sym)
        end
      end
    end
  end
end
