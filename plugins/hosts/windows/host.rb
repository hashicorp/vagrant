require "vagrant"
require 'vagrant/util/platform'

module VagrantPlugins
  module HostWindows
    class Host < Vagrant.plugin("2", :host)
      def self.match?
        Vagrant::Util::Platform.windows?
      end

      # Windows does not support NFS
      def nfs?
        false
      end
    end
  end
end
