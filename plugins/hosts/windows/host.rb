require "vagrant"

require 'vagrant/util/platform'

module VagrantPlugins
  module HostWindows
    class Host < Vagrant.plugin("2", :host)
      def detect?(env)
        Vagrant::Util::Platform.windows?
      end
    end
  end
end
