# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require 'vagrant/util/guest_inspection'
require "log4r"

module VagrantPlugins
  module GuestLinux
    module Cap
      class Reboot
        extend Vagrant::Util::GuestInspection::Linux

        DEFAULT_MAX_REBOOT_RETRY_DURATION = 120
        WAIT_SLEEP_TIME = 5

        def self.reboot(machine)
          @logger = Log4r::Logger.new("vagrant::linux::reboot")
          reboot_script = "ps -q 1 -o comm=,start= > /tmp/.vagrant-reboot"

          if systemd?(machine.communicate)
            reboot_cmd = "systemctl reboot"
          else
            reboot_cmd = "reboot"
          end

          comm = machine.communicate
          reboot_script += "; #{reboot_cmd}"

          @logger.debug("Issuing reboot command for guest")
          comm.sudo(reboot_script)

          machine.ui.info(I18n.t("vagrant.guests.capabilities.rebooting"))

          @logger.debug("Waiting for machine to finish rebooting")

          wait_remaining = ENV.fetch("VAGRANT_MAX_REBOOT_RETRY_DURATION",
            DEFAULT_MAX_REBOOT_RETRY_DURATION).to_i
          wait_remaining = DEFAULT_MAX_REBOOT_RETRY_DURATION if wait_remaining < 1

          begin
            wait_for_reboot(machine)
          rescue Vagrant::Errors::MachineGuestNotReady
            raise if wait_remaining < 0
            @logger.warn("Machine not ready, cannot start reboot yet. Trying again")
            sleep(WAIT_SLEEP_TIME)
            wait_remaining -= WAIT_SLEEP_TIME
            retry
          end
        end

        def self.wait_for_reboot(machine)
          caught = false
          begin
            check_script = 'grep "$(ps -q 1 -o comm=,start=)" /tmp/.vagrant-reboot'
            while machine.guest.ready? && machine.communicate.execute(check_script, error_check: false) == 0
              sleep 10
            end
          rescue
            # The check script execution may result in an exception
            # getting raised depending on the state of the communicator
            # when executing. We'll allow for it to happen once, and then
            # raise if we get an exception again
            if caught
              raise
            end
            caught = true
            sleep 10
            retry
          end
        end
      end
    end
  end
end
