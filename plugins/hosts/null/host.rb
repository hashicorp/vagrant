require "vagrant"

module VagrantPlugins
  module HostNull
    class Host < Vagrant.plugin("2", :host)
      def detect?(env)
        # This host can only be explicitly chosen.
        false
      end
    end
  end
end
