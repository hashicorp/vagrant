require "vagrant"

module VagrantPlugins
  module Kernel_V1
    class PackageConfig < Vagrant.plugin("1", :config)
      attr_accessor :name
    end
  end
end
