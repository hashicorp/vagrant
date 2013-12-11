require "vagrant"

module VagrantPlugins
  module SyncedFolderNFSGuest
    class Config < Vagrant.plugin("2", :config)
      attr_accessor :map_uid
      attr_accessor :map_gid

      def initialize
        super

        @map_uid = UNSET_VALUE
        @map_gid = UNSET_VALUE
      end

      def finalize!
        @map_uid = nil if @map_uid == UNSET_VALUE
        @map_gid = nil if @map_gid == UNSET_VALUE
      end

      def to_s
        "NFSGuest"
      end
    end
  end
end
