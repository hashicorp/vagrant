require "vagrant"

module VagrantPlugins
  module HostGentoo
    class Host < Vagrant.plugin("2", :host)
      def detect?(env)
        File.exists?("/etc/gentoo-release")
      end
    end
  end
end
