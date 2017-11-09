module VagrantPlugins
  module GuestMINIX
    module Cap
      class ChangeHostName
        def self.change_host_name(machine, name)
          if !machine.communicate.test("hostname -s | grep '^#{name}$'")
            machine.communicate.sudo(<<CMDS, {shell: "sh"})
hostname #{name}
CMDS
          end
        end
      end
    end
  end
end
