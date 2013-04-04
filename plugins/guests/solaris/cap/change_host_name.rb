module VagrantPlugins
  module GuestSolaris
    module Cap
      class ChangeHostName
        def self.change_host_name(machine, name)
          su_cmd = machine.config.solaris.suexec_cmd

          # Only do this if the hostname is not already set
          if !machine.communicate.test("#{su_cmd} hostname | grep '#{name}'")
            machine.communicate.execute("#{su_cmd} sh -c \"echo '#{name}' > /etc/nodename\"")
            machine.communicate.execute("#{su_cmd} uname -S #{name}")
          end
        end
      end
    end
  end
end
