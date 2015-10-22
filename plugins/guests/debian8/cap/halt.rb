module VagrantPlugins
  module GuestDebian8
    module Cap
    class Halt
        def self.halt(machine)
          begin
            machine.communicate.tap do |comm|
              if comm.test("lsmod |grep -w vboxguest")
                machine.communicate.sudo("shutdown -h now")
              else
                machine.communicate.sudo("shutdown -h -H")
              end
            end
          rescue IOError
            # Do nothing, because it probably means the machine shut down
            # and SSH connection was lost.
          end
        end
      end
    end
  end
end
