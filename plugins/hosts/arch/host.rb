require 'vagrant'

module VagrantPlugins
  module HostArch
    class Host < Vagrant.plugin('2', :host)
      def detect?(_env)
        File.exist?('/etc/arch-release')
      end
    end
  end
end
