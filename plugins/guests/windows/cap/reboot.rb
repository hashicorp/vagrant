require "log4r"

module VagrantPlugins
  module GuestWindows
    module Cap
      class Reboot
        DEFAULT_MAX_REBOOT_RETRY_DURATION = 120
        WAIT_SLEEP_TIME = 5

        def self.reboot(machine)
          @logger = Log4r::Logger.new("vagrant::windows::reboot")
          reboot_script = "shutdown /r /t 5 /f /d p:4:1 /c \"Vagrant Reboot Computer\""

          comm = machine.communicate

          script  = File.expand_path("../../scripts/reboot_detect.ps1", __FILE__)
          script  = File.read(script)
          if comm.test(script, error_check: false, shell: :powershell)
            @logger.debug("Issuing reboot command for guest")
            comm.execute(reboot_script, shell: :powershell)
          else
            @logger.debug("A reboot is already in progress")
          end

          machine.ui.info(I18n.t("vagrant.guests.capabilities.rebooting"))

          @logger.debug("Waiting for machine to finish rebooting")

          wait_remaining = ENV.fetch("VAGRANT_MAX_REBOOT_RETRY_DURATION",
            DEFAULT_MAX_REBOOT_RETRY_DURATION).to_i
          wait_remaining = DEFAULT_MAX_REBOOT_RETRY_DURATION if wait_remaining < 1

          begin
            wait_for_reboot(machine)
          rescue => err
            raise if wait_remaining < 0
            @logger.debug("Exception caught while waiting for reboot: #{err}")
            @logger.warn("Machine not ready, cannot start reboot yet. Trying again")
            sleep(WAIT_SLEEP_TIME)
            wait_remaining -= WAIT_SLEEP_TIME
            retry
          end
        end

        def self.wait_for_reboot(machine)
          script  = File.expand_path("../../scripts/reboot_detect.ps1", __FILE__)
          script  = File.read(script)

          while machine.guest.ready? && machine.communicate.execute(script, error_check: false, shell: :powershell) != 0
            sleep 10
          end

          # This re-establishes our symbolic links if they were
          # created between now and a reboot
          machine.communicate.execute("net use", error_check: false, shell: :powershell)
        end
      end
    end
  end
end
