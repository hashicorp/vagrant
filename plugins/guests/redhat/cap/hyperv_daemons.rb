module VagrantPlugins
  module GuestRedHat
    module Cap
      class HypervDaemons
        def self.hyperv_daemons_installed(machine)
          machine.communicate.test("rpm -q hyperv-daemons")
        end

        def self.hyperv_daemons_install(machine)
          comm = machine.communicate
          comm.sudo <<-EOH.gsub(/^ {12}/, "")
            if command -v dnf; then
              dnf -y install hyperv-daemons
            else
              yum -y install hyperv-daemons
            fi
          EOH
        end
      end
    end
  end
end
