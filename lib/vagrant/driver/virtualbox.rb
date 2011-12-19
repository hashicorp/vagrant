require 'vagrant/util/subprocess'

module Vagrant
  module Driver
    # This class contains the logic to drive VirtualBox.
    class VirtualBox
      # Include this so we can use `Subprocess` more easily.
      include Vagrant::Util

      # The version of virtualbox that is running.
      attr_reader :version

      def initialize
        # Read and assign the version of VirtualBox we know which
        # specific driver to instantiate.
        begin
          @version = read_version
        rescue Subprocess::ProcessFailedToStart
          # This means that VirtualBox was not found, so we raise this
          # error here.
          raise Errors::VirtualBoxNotDetected
        end
      end

      protected

      # This returns the version of VirtualBox that is running.
      #
      # @return [String]
      def read_version
        result = Subprocess.execute("VBoxManage", "--version")
        result.stdout.split("r")[0]
      end
    end
  end
end
