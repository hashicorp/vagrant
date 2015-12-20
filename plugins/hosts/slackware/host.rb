require "vagrant"

module VagrantPlugins
  module HostSlackware
    class Host < Vagrant.plugin("2", :host)
      def detect?(env)
        return File.exists?("/etc/slackware-version") ||
          !Dir.glob("/usr/lib/setup/Plamo-*").empty?
      end
    end
  end
end
