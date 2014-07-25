require 'vagrant'

module VagrantPlugins
  module HostLinux
    # Represents a Linux based host, such as Ubuntu.
    class Host < Vagrant.plugin('2', :host)
      def detect?(_env)
        Vagrant::Util::Platform.linux?
      end
    end
  end
end
