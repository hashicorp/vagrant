require "vagrant"
require 'vagrant/util/platform'

module VagrantPlugins
  module HostFreeBSD
    class Host < Vagrant.plugin("2", :host)
      def self.detect?(env)
        Vagrant::Util::Platform.freebsd?
      end
    end
  end
end
