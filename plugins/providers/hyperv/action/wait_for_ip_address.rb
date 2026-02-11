# Copyright IBM Corp. 2010, 2025
# SPDX-License-Identifier: BUSL-1.1

require "ipaddr"
require "timeout"

module VagrantPlugins
  module HyperV
    module Action
      class WaitForIPAddress
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant::hyperv::wait_for_ip_addr")
        end

        def call(env)
          timeout = env[:machine].provider_config.ip_address_timeout
          ipv4_only = env[:machine].provider_config.ipv4_only

          env[:ui].output("Waiting for the machine to report its IP address...")
          env[:ui].detail("Timeout: #{timeout} seconds")
          if ipv4_only
            env[:ui].detail("Waiting for IPv4 address only")
          end

          guest_ip = nil
          Timeout.timeout(timeout) do
            while true
              # If a ctrl-c came through, break out
              return if env[:interrupted]

              # Try to get the IP
              begin
                network_info = env[:machine].provider.driver.read_guest_ip
                guest_ip = network_info["ip"]

                if guest_ip
                  begin
                    ip = IPAddr.new(guest_ip)
                    break unless ipv4_only && !ip.ipv4?()
                  rescue IPAddr::InvalidAddressError
                    # Ignore, continue looking.
                    @logger.warn("Invalid IP address returned: #{guest_ip}")
                  end
                end
              rescue Errors::PowerShellError
                # Ignore, continue looking.
                @logger.warn("Failed to read guest IP.")
              end
              sleep 1
            end
          end

          # If we were interrupted then return now
          return if env[:interrupted]

          env[:ui].detail("IP: #{guest_ip}")

          @app.call(env)
        rescue Timeout::Error
          raise Errors::IPAddrTimeout
        end
      end
    end
  end
end
