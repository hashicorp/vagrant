module VagrantPlugins
  module GuestTrisquel
    class Guest < Vagrant.plugin("2", :guest)
      def detect?(machine)
        machine.communicate.test("[ -x /usr/bin/lsb_release ] && /usr/bin/lsb_release -i 2>/dev/null | grep Trisquel")
      end
    end
  end
end
