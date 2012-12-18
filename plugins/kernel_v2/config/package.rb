require "vagrant"

module VagrantPlugins
  module Kernel_V2
    class PackageConfig < Vagrant.plugin("2", :config)
      attr_accessor :name
    end
  end
end
