module VagrantPlugins
  module CommandRDP
    class Config < Vagrant.plugin("2", :config)
      attr_accessor :port
      attr_accessor :search_port
      attr_accessor :username

      def initialize
        @port        = UNSET_VALUE
        @search_port = UNSET_VALUE
        @username = UNSET_VALUE
      end

      def finalize!
        @port        = 3389 if @port == UNSET_VALUE
        @search_port = 3389 if @search_port == UNSET_VALUE
        @username = nil if @username == UNSET_VALUE
      end

      def validate(machine)
        errors = _detected_errors
        { "RDP" => errors }
      end
    end
  end
end
