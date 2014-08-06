require "log4r"

module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class SaneDefaults
        def initialize(app, env)
          @logger = Log4r::Logger.new("vagrant::action::vm::sanedefaults")
          @app = app
        end

        def call(env)
          # Set the env on an instance variable so we can access it in
          # helpers.
          @env = env

          # Use rtcuseutc so that the VM sees UTC time.
          command = ["modifyvm", env[:machine].id, "--rtcuseutc", "on"]
          attempt_and_log(command, "Enabling rtcuseutc...")

          if env[:machine].provider_config.auto_nat_dns_proxy
            @logger.info("Automatically figuring out whether to enable/disable NAT DNS proxy...")

            # Enable/disable the NAT DNS proxy as necessary
            if enable_dns_proxy?
              command = ["modifyvm", env[:machine].id, "--natdnsproxy1", "on"]
              attempt_and_log(command, "Enable the NAT DNS proxy on adapter 1...")
            else
              command = ["modifyvm", env[:machine].id, "--natdnsproxy1", "off" ]
              attempt_and_log(command, "Disable the NAT DNS proxy on adapter 1...")
              command = ["modifyvm", env[:machine].id, "--natdnshostresolver1", "off" ]
              attempt_and_log(command, "Disable the NAT DNS resolver on adapter 1...")
            end
          else
            @logger.info("NOT trying to automatically manage NAT DNS proxy.")
          end

          @app.call(env)
        end

        protected

        # This is just a helper method that executes a single command, logs
        # the given string to the log, and also includes the exit status in
        # the log message.
        #
        # We assume every command is idempotent and pass along the `retryable`
        # flag. This is because VBoxManage is janky about running simultaneously
        # on the same box, and if we up multiple boxes at the same time, a bunch
        # of modifyvm commands get fired
        #
        # @param [Array] command Command to run
        # @param [String] log Log message to write.
        def attempt_and_log(command, log)
          begin
            @env[:machine].provider.driver.execute_command(
              command + [retryable: true])
          rescue Vagrant::Errors::VBoxManageError => e
            @logger.info("#{log} (error = #{e.inspect})")
          end
        end

        # This uses some heuristics to determine if the NAT DNS proxy should
        # be enabled or disabled. See the comments within the function body
        # itself to see the checks it does.
        #
        # @return [Boolean]
        def enable_dns_proxy?
          begin
            contents = File.read("/etc/resolv.conf")

            if contents =~ /^nameserver 127\.0\.(0|1)\.1$/
              # The use of both natdnsproxy and natdnshostresolver break on
              # Ubuntu 12.04 and 12.10 that uses resolvconf with localhost. When used
              # VirtualBox will give the client dns server 10.0.2.3, while
              # not binding to that address itself. Therefore disable this
              # feature if host uses the resolvconf server 127.0.0.1 or
              # 127.0.1.1
              @logger.info("Disabling DNS proxy since resolv.conf contains 127.0.0.1 or 127.0.1.1")
              return false
            end
          rescue Errno::ENOENT; end

          return true
        end
      end
    end
  end
end
