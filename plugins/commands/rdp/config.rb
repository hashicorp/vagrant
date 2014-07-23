module VagrantPlugins
  module CommandRDP
    class Config < Vagrant.plugin('2', :config)
      attr_accessor :port
      attr_accessor :search_port

      def initialize
        @port        = UNSET_VALUE
        @search_port = UNSET_VALUE
      end

      def finalize!
        @port        = 3389 if @port == UNSET_VALUE
        @search_port = 3389 if @search_port == UNSET_VALUE
      end

      def validate(_machine)
        errors = _detected_errors
        { 'RDP' => errors }
      end
    end
  end
end
