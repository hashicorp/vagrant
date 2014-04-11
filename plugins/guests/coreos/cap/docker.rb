module VagrantPlugins
  module GuestCoreOS
    module Cap
      module Docker
        def self.docker_daemon_running(machine)
          machine.communicate.test("test -f /run/docker.sock")
        end
      end
    end
  end
end
