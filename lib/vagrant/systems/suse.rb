module Vagrant
  module Systems
    class Suse < Redhat
      def network_scripts_dir
        '/etc/sysconfig/network/'
      end 
    end
  end
end
