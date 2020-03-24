module VagrantPlugins
  module GuestArch
    module Cap
      class HypervDaemons
        def self.hyperv_daemons_installed(machine)
          machine.communicate.test("pacman -Q hyperv")
        end

        def self.hyperv_daemons_install(machine)
          comm = machine.communicate
          comm.sudo <<-EOH.gsub(/^ {12}/, "")
            pacman --noconfirm -Syy &&
            pacman --noconfirm -S hyperv
          EOH
        end
      end
    end
  end
end
