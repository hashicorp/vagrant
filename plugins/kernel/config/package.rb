require "vagrant"

module VagrantPlugins
  module Kernel
    class PackageConfig < Vagrant::Config::V1::Base
      attr_accessor :name
    end
  end
end
