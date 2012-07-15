require "vagrant"

module VagrantPlugins
  module ProviderVirtualBox
    class Plugin < Vagrant.plugin("1")
      name "virtualbox provider"
      description <<-EOF
      The VirtualBox provider allows Vagrant to manage and control
      VirtualBox-based virtual machines.
      EOF

      provider("virtualbox") do
        require File.expand_path("../provider", __FILE__)
        Provider
      end
    end
  end
end
