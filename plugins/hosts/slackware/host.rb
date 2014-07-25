require 'vagrant'

module VagrantPlugins
  module HostSlackware
    class Host < Vagrant.plugin('2', :host)
      def detect?(_env)
        File.exist?('/etc/slackware-release') ||
          !Dir.glob('/usr/lib/setup/Plamo-*').empty?
      end
    end
  end
end
