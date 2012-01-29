module Vagrant
  module Action
    module VM
      # edit /etc/hosts on host machine.
      # for redirect domain names to guest machine
      class DOMAIN
        include Vagrant::Util
        def initialize(app,env)
          @app = app
          @env = env

          verify_settings if domain_enabled?
        end

        def call(env)
          @env = env
          configure_hosts_file
        end

        def configure_hosts_file
          domains = @env[:vm].config.vm.domains
          # replace domain if exist in /etc/hosts
          domains.split(' ').each do |domain|
            system(%Q[sudo su root -c "sed -i 's/#{domain}/changedbyvagrant.#{domain}/g' /etc/hosts"])
          end
          ip = guest_ip
          # remove string with guest ip
          system(%Q[sudo su root -c "sed -i '/#{ip}/d' /etc/hosts"])
          # string like 10.20.30.1 domain1.com domain2.com domain3.ru
          str = ip.to_s + ' ' + domains
          system(%Q[sudo su root -c "echo -e '# VAGRANT-BEGIN' >> /etc/hosts"])
          system(%Q[sudo su root -c "echo -e '#{str}' >> /etc/hosts"])
          system(%Q[sudo su root -c "echo -e '# VAGRANT-END' >> /etc/hosts"])
        end

        # Returns the IP address of the guest by looking at the first
        # enabled host only network.
        #
        # @return [String]
        def guest_ip
          @env[:vm].config.vm.networks.each do |type, args|
            if type == :hostonly && args[0].is_a?(String)
              return args[0]
            end
          end

          nil
        end

        def domain_enabled?
          !@env[:vm].config.vm.domains.nil?
        end

        def verify_settings
          raise Errors::NFSHostRequired if @env[:host].nil?
          raise Errors::NFSNoHostNetwork if !guest_ip
        end
      end
    end
  end
end
