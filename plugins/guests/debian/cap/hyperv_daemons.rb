module VagrantPlugins
  module GuestDebian
    module Cap
      class HypervDaemons
        def self.hyperv_daemons_installed(machine)
          machine.communicate.test('dpkg -s linux-cloud-tools-common', sudo: true)
        end

        def self.hyperv_daemons_install(machine)
          comm = machine.communicate
          comm.sudo <<-EOH.gsub(/^ {12}/, "")
            DEBIAN_FRONTEND=noninteractive apt-get update -y &&
            apt-get install -y -o Dpkg::Options::="--force-confdef" linux-cloud-tools-common
          EOH
        end
      end
    end
  end
end
