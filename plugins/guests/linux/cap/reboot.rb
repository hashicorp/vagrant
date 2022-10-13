require 'vagrant/util/guest_inspection'
require "log4r"

module VagrantPlugins
  module GuestLinux
    module Cap
      class Reboot
        extend Vagrant::Util::GuestInspection::Linux
        MAX_REBOOT_RETRY_DURATION = 120

        def self.reboot(machine)
          @logger = Log4r::Logger.new("vagrant::linux::reboot")
          if systemd?(machine.communicate)
            reboot_script = "systemctl reboot"
          else
            reboot_script = "reboot"
          end

          comm = machine.communicate

          @logger.debug("Issuing reboot command for guest")
          comm.sudo(reboot_script)

          machine.ui.info(I18n.t("vagrant.guests.capabilities.rebooting"))

          @logger.debug("Waiting for machine to finish rebooting")

          wait_remaining = MAX_REBOOT_RETRY_DURATION
          begin
            wait_for_reboot(machine)
          rescue Vagrant::Errors::MachineGuestNotReady => e
            raise if wait_remaining < 0
            @logger.warn("Machine not ready, cannot start reboot yet. Trying again")
            sleep(5)
            wait_remaining -= 5
            retry
          end
        end

        def self.wait_for_reboot(machine)
          while !machine.guest.ready?
            sleep 10
          end
        end
      end
    end
  end
end
