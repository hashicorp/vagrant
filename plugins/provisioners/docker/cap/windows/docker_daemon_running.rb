module VagrantPlugins
  module DockerProvisioner
    module Cap
      module Windows
        module DockerDaemonRunning
          def self.docker_daemon_running(machine)
            machine.communicate.test("tasklist | find \"`\"dockerd`\"\"")
          end
        end
      end
    end
  end
end
