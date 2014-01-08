require "pathname"

require "vagrant"

module VagrantPlugins
  module HostOpenSUSE
    class Host < Vagrant.plugin("2", :host)
      def detect?(env)
        release_file = Pathname.new("/etc/SuSE-release")

        if release_file.exist?
          release_file.open("r") do |f|
            return true if f.gets =~ /^openSUSE/
          end
        end

        false
      end
    end
  end
end
