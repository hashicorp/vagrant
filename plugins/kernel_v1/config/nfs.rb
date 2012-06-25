require "vagrant"

module VagrantPlugins
  module Kernel_V1
    class NFSConfig < Vagrant::Plugin::V1::Config
      attr_accessor :map_uid
      attr_accessor :map_gid
    end
  end
end
