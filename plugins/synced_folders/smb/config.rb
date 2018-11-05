require "vagrant"

module VagrantPlugins
  module SyncedFolderSMB
    class Config < Vagrant.plugin("2", :config)
      attr_accessor :functional

      def initialize
        super

        @functional = UNSET_VALUE
      end

      def finalize!
        @functional = true if @functional == UNSET_VALUE
      end

      def to_s
        "SMB"
      end
    end
  end
end
