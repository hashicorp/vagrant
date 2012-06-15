require "vagrant"

module VagrantPlugins
  module Kernel_V1
    class NFSConfig < Vagrant::Config::V1::Base
      attr_accessor :map_uid
      attr_accessor :map_gid
    end
  end
end
