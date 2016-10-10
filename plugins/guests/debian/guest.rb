require "vagrant"

module VagrantPlugins
  module GuestDebian
    class Guest < Vagrant.plugin("2", :guest)
      def detect?(machine)
        machine.communicate.test <<-EOH.gsub(/^ {10}/, "")
          if test -r /etc/os-release; then
            source /etc/os-release && test xdebian = x$ID
          elif test -x /usr/bin/lsb_release; then
            /usr/bin/lsb_release -i 2>/dev/null | grep -q Debian
          elif test -r /etc/issue; then
            cat /etc/issue | grep 'Debian'
          else
            exit 1
          fi
        EOH
      end
    end
  end
end
