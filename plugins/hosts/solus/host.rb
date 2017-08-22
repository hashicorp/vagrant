require "vagrant"

module VagrantPlugins
  module HostSolus
    class Host < Vagrant.plugin("2", :host)
      def detect?(env)
        File.exist?("/etc/solus-release")
      end
    end
  end
end
