module VagrantPlugins
  module GuestSlackware
    class Guest < Vagrant.plugin("2", :guest)
      def detect?(machine)
        machine.communicate.test("cat /etc/slackware-version")
      end
    end
  end
end
