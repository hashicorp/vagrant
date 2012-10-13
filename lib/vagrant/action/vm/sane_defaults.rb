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

          enable_dns_proxy = true
          begin
            contents = File.read("/etc/resolv.conf")

            if contents =~ /^nameserver 127\.0\.(0|1)\.1$/
              # The use of both natdnsproxy and natdnshostresolver break on
              # Ubuntu 12.04 that uses resolvconf with localhost. When used
              # VirtualBox will give the client dns server 10.0.2.3, while
              # not binding to that address itself. Therefore disable this
              # feature if host uses the resolvconf server 127.0.0.1
              @logger.info("Disabling DNS proxy since resolv.conf contains 127.0.0.1")
              enable_dns_proxy = false
            end
          rescue Errno::ENOENT; end

          # Enable/disable the NAT DNS proxy as necessary
          if enable_dns_proxy
            command = [
              "modifyvm", env[:vm].uuid,
              "--natdnsproxy1", "on"
            ]
            attempt_and_log(command, "Enable the NAT DNS proxy on adapter 1...")
          else
            command = [ "modifyvm", env[:vm].uuid, "--natdnsproxy1", "off" ]
            attempt_and_log(command, "Disable the NAT DNS proxy on adapter 1...")
            command = [ "modifyvm", env[:vm].uuid, "--natdnshostresolver1", "off" ]
            attempt_and_log(command, "Disable the NAT DNS resolver on adapter 1...")
          end

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
