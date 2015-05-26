require "vagrant"

module VagrantPlugins
  module Kernel_V2
    class SyncedFolderConfig < Vagrant.plugin("2", :config)
      attr_accessor :username
      attr_accessor :password

      def initialize
        @username = UNSET_VALUE
        @password = UNSET_VALUE
      end

      def finalize!
        @username = nil if @username == UNSET_VALUE
        @password = nil if @password == UNSET_VALUE
      end

      def to_s
        "SyncedFolder"
      end
    end
  end
end