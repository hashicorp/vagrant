module Vagrant
  class Config
    class VagrantConfig < Base
      Config.configures :vagrant, self

      attr_accessor :dotfile_name
      attr_accessor :log_output
      attr_writer :home
      attr_accessor :host

      def initialize
        @home = nil
      end

      def home
        @home ? File.expand_path(@home) : nil
      end
    end
  end
end
