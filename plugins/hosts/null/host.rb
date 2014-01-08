require "vagrant"

module VagrantPlugins
  module HostNull
    class Host < Vagrant.plugin("2", :host)
      def detect?
        # This host can only be explicitly chosen.
        false
      end
    end
  end
end
