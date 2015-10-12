module VagrantPlugins
  module GuestAtomic
    module Cap
      module Docker
        def self.docker_daemon_running(machine)
          machine.communicate.test("test -S /run/docker.sock")
        end
      end
    end
  end
end
