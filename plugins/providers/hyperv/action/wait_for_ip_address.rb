require "timeout"
module VagrantPlugins
  module HyperV
    module Action
      class WaitForIPAddress
        def initialize(app, env)
          @app = app
        end

        def call(env)
          timeout = env[:machine].provider_config.ip_address_timeout

          env[:ui].output("Waiting for the machine to report its IP address...")
          env[:ui].detail("Timeout: #{timeout} seconds")

          guest_ip = nil
          Timeout.timeout(timeout) do
            while true
              # If a ctrl-c came through, break out
              return if env[:interrupted]

              # Try to get the IP
              network_info = env[:machine].provider.driver.read_guest_ip
              guest_ip = network_info["ip"]
              # Check if the guest IP is a valid IP Address.
              break if guest_ip && !(/\d+(\.)\d+(\.)\d+(\.)\d+/.match(guest_ip).nil?)
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
