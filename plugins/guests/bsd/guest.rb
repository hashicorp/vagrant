module VagrantPlugins
  module GuestBSD
    class Guest < Vagrant.plugin("2", :guest)
      def detect?(machine)
        machine.communicate.test("uname -s | grep -iE 'Darwin|BSD|DragonFly'")
      end
    end
  end
end
