require "vagrant"

module VagrantPlugins
  module SyncedFolderNFS
    class Config < Vagrant.plugin("2", :config)
      attr_accessor :functional
      attr_accessor :map_uid
      attr_accessor :map_gid
      attr_accessor :verify_installed

      def initialize
        super

        @functional = UNSET_VALUE
        @map_uid    = UNSET_VALUE
        @map_gid    = UNSET_VALUE
        @verify_installed = UNSET_VALUE
      end

      def finalize!
        @functional = true if @functional == UNSET_VALUE
        @map_uid = :auto if @map_uid == UNSET_VALUE
        @map_gid = :auto if @map_gid == UNSET_VALUE
        @verify_installed = true if @verify_installed == UNSET_VALUE
      end

      def to_s
        "NFS"
      end
    end
  end
end
