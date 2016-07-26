module VagrantPlugins
  module GuestSmartos
    class Config < Vagrant.plugin("2", :config)
      # This sets the command to use to execute items as a superuser.
      # @default sudo
      attr_accessor :suexec_cmd
      attr_accessor :device

      def initialize
        @suexec_cmd = 'pfexec'
        @device     = "e1000g"
      end
    end
  end
end
