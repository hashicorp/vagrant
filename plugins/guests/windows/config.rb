module VagrantPlugins
  module GuestWindows
    class Config < Vagrant.plugin("2", :config)
      attr_accessor :set_work_network

      def initialize
        @set_work_network = UNSET_VALUE
      end

      def validate(machine)
        errors = []

        errors << "windows.set_work_network cannot be nil." if @set_work_network.nil?

        { "Windows Guest" => errors }
      end

      def finalize!
        @set_work_network = false if @set_work_network == UNSET_VALUE
      end
    end
  end
end
