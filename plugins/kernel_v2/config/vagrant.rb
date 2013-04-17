require "vagrant"

module VagrantPlugins
  module Kernel_V2
    class VagrantConfig < Vagrant.plugin("2", :config)
      attr_accessor :host
      attr_accessor :default_machines

      def to_s
        "Vagrant"
      end
    end
  end
end
