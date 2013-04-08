module VagrantPlugins
  module CFEngine
    module Cap
      module Linux
        module CFEngineInstalled
          def self.cfengine_installed(machine)
            machine.communicate.test(
              "test -d /var/cfengine && test -x /var/cfengine/bin/cf-agent", sudo: true)
          end
        end
      end
    end
  end
end
