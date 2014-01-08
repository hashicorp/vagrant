require "vagrant"

require 'vagrant/util/platform'

module VagrantPlugins
  module HostWindows
    class Host < Vagrant.plugin("2", :host)
      def self.detect?(env)
        Vagrant::Util::Platform.windows?
      end
    end
  end
end
