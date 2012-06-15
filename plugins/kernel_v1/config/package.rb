require "vagrant"

module VagrantPlugins
  module Kernel_V1
    class PackageConfig < Vagrant::Config::V1::Base
      attr_accessor :name
    end
  end
end
