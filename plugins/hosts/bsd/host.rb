require 'vagrant'

module VagrantPlugins
  module HostBSD
    # Represents a BSD host, such as FreeBSD.
    class Host < Vagrant.plugin('2', :host)
      def detect?(_env)
        Vagrant::Util::Platform.darwin?
      end
    end
  end
end
