require "vagrant/util/platform"

module VagrantPlugins
  module HostDarwin
    class Host < Vagrant.plugin("2", :host)
      def detect?(env)
        Vagrant::Util::Platform.darwin?
      end
    end
  end
end
