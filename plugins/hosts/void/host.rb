require 'pathname'

require 'vagrant'

module VagrantPlugins
  module HostVoid
    class Host < Vagrant.plugin("2", :host)
      def detect?(env)
        os_file = Pathname.new("/etc/os-release")

        if os_file.exist?
          file = os_file.open
          while (line = file.gets) do
            return true if line =~ /^ID="void"/
          end
        end

        false
      end
    end
  end
end
