module VagrantPlugins
  module GuestEsxi
    module Cap
      class ChangeHostName
        def self.change_host_name(machine, name)
          if !machine.communicate.test("localcli system hostname get | grep '#{name}'")
            machine.communicate.execute("localcli system hostname set -H '#{name}'")
          end
        end
      end
    end
  end
end
