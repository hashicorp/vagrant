module VagrantPlugins
  module GuestSmartos
    module Cap
      class ChangeHostName
        def self.change_host_name(machine, name)
          sudo = machine.config.smartos.suexec_cmd

          machine.communicate.tap do |comm|
            comm.execute <<-EOH.sub(/^ */, '')
              if hostname | grep '#{name}' ; then
                exit 0
              fi

              if [ -d /usbkey ] && [ "$(zonename)" == "global" ] ; then
                #{sudo} sed -i '' 's/hostname=.*/hostname=#{name}/' /usbkey/config
              fi

              #{sudo} echo '#{name}' > /etc/nodename
              #{sudo} hostname #{name}
            EOH
          end
        end
      end
    end
  end
end
