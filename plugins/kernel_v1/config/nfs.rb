require "vagrant"

module VagrantPlugins
  module Kernel_V1
    class NFSConfig < Vagrant.plugin("1", :config)
      attr_accessor :map_uid
      attr_accessor :map_gid

      def initialize
        @map_uid = UNSET_VALUE
        @map_gid = UNSET_VALUE
      end

      def upgrade(new)
        new.nfs.map_uid = @map_uid if @map_uid != UNSET_VALUE
        new.nfs.map_gid = @map_gid if @map_gid != UNSET_VALUE
      end
    end
  end
end
