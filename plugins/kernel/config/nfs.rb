require "vagrant"

module VagrantPlugins
  module Kernel
    class NFSConfig < Vagrant::Config::V1::Base
      attr_accessor :map_uid
      attr_accessor :map_gid

      def initialize
        @map_uid = UNSET_VALUE
        @map_gid = UNSET_VALUE
      end
    end
  end
end
