require "vagrant"

module VagrantPlugins
  module Kernel_V1
    class VagrantConfig < Vagrant::Plugin::V1::Config
      attr_accessor :dotfile_name
      attr_accessor :host
    end
  end
end
