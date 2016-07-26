module VagrantPlugins
  module GuestUbuntu
    class Guest < Vagrant.plugin("2", :guest)
      def detect?(machine)
        # This command detects if we are running on Ubuntu. /etc/os-release is
        # available on modern Ubuntu versions, but does not exist on 14.04 and
        # previous versions, so we fall back to lsb_release.
        #
        #   GH-7524
        #   GH-7625
        #
        machine.communicate.test <<-EOH.gsub(/^ {10}/, "")
          if test -r /etc/os-release; then
            source /etc/os-release && test xubuntu = x$ID
          elif test -x /usr/bin/lsb_release; then
            /usr/bin/lsb_release -i 2>/dev/null | grep -q Ubuntu
          else
            exit 1
          fi
        EOH
      end
    end
  end
end
