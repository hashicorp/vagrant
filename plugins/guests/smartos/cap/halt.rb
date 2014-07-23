module VagrantPlugins
  module GuestSmartos
    module Cap
      class Halt
        def self.halt(machine)
          # There should be an exception raised if the line
          #
          #     vagrant::::profiles=Primary Administrator
          #
          # does not exist in /etc/user_attr. TODO
          machine.communicate.execute(
            "#{machine.config.smartos.suexec_cmd} /usr/sbin/shutdown -y -i5 -g0")
        rescue IOError
        end
      end
    end
  end
end
