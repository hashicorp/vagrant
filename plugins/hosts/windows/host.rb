require 'vagrant/util/platform'

module VagrantPlugins
  module HostWindows
    class Host < Vagrant::Hosts::Base
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
