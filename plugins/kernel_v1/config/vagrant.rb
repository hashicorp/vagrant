require "vagrant"

module VagrantPlugins
  module Kernel_V1
    class VagrantConfig < Vagrant.plugin("1", :config)
      attr_accessor :dotfile_name
      attr_accessor :host
    end
  end
end
