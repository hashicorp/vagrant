require "vagrant"

module VagrantPlugins
  module HostBSD
    # Represents a BSD host, such as FreeBSD and Darwin (Mac OS X).
    class Host < Vagrant.plugin("2", :host)
      def detect?(env)
        Vagrant::Util::Platform.darwin? || Vagrant::Util::Platform.bsd?
      end
    end
  end
end
