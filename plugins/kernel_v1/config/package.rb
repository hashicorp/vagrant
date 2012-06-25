require "vagrant"

module VagrantPlugins
  module Kernel_V1
    class PackageConfig < Vagrant::Plugin::V1::Config
      attr_accessor :name
    end
  end
end
