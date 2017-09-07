require "vagrant"

module VagrantPlugins
  module HostSolus
    class Host < Vagrant.plugin("2", :host)
      def detect?(env)
      	if File.exist?("/etc/os-release")
      		File.readlines("/etc/os-release").grep(/^ID=["']{0,1}solus["']{0,1}$/).any?
      	end
      end
    end
  end
end
