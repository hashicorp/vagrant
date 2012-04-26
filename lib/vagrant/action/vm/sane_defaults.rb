require "log4r"

module Vagrant
  module Action
    module VM
      # This middleware enforces some sane defaults on the virtualbox
      # VM which help with performance, stability, and in some cases
      # behavior.
      class SaneDefaults
        def initialize(app, env)
          @logger = Log4r::Logger.new("vagrant::action::vm::sanedefaults")
          @app = app
        end

        def call(env)
          # Set the env on an instance variable so we can access it in
          # helpers.
          @env = env

          # Enable the host IO cache on the sata controller. Note that
          # if this fails then its not a big deal, so we don't raise any
          # errors. The Host IO cache vastly improves disk IO performance
          # for VMs.
          command = [
            "storagectl", env[:vm].uuid,
            "--name", "SATA Controller",
            "--hostiocache", "on"
          ]
          attempt_and_log(command, "Enabling the Host I/O cache on the SATA controller...")

          # Enable the DNS proxy while in NAT mode.  This shields the guest
          # VM from external DNS changs on the host machine.
          command = [
            "modifyvm", env[:vm].uuid,
            "--natdnsproxy1", "on"
          ]
          attempt_and_log(command, "Enable the NAT DNS proxy on adapter 1...")

          @app.call(env)
        end

        protected

        # This is just a helper method that executes a single command, logs
        # the given string to the log, and also includes the exit status in
        # the log message.
        #
        # @param [Array] command Command to run
        # @param [String] log Log message to write.
        def attempt_and_log(command, log)
          result = @env[:vm].driver.execute_command(command)
          @logger.info("#{log} (exit status = #{result.exit_code})")
        end
      end
    end
  end
end
