module VagrantPlugins
  module GuestLinux
    class Guest < Vagrant.plugin("2", :guest)
      # Name used for guest detection
      GUEST_DETECTION_NAME = "linux".freeze

      def detect?(machine)
        machine.communicate.test <<-EOH.gsub(/^ */, '')
          if test -r /etc/os-release; then
            source /etc/os-release && test 'x#{self.class.const_get(:GUEST_DETECTION_NAME)}' = "x$ID" && exit
          fi
          if test -x /usr/bin/lsb_release; then
            /usr/bin/lsb_release -i 2>/dev/null | grep -qi '#{self.class.const_get(:GUEST_DETECTION_NAME)}' && exit
          fi
          if test -r /etc/issue; then
            cat /etc/issue | grep -qi '#{self.class.const_get(:GUEST_DETECTION_NAME)}' && exit
          fi
          exit 1
        EOH
      end
    end
  end
end
