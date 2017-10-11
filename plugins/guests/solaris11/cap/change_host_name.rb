# A general Vagrant system implementation for "solaris 11".
#
# Contributed by Jan Thomas Moldung <janth@moldung.no>

module VagrantPlugins
  module GuestSolaris11
    module Cap
      class ChangeHostName
        def self.change_host_name(machine, name)
          su_cmd = machine.config.solaris11.suexec_cmd

          # Only do this if the hostname is not already set
          if !machine.communicate.test("/usr/sbin/svccfg -s system/identity:node listprop config/nodename | /usr/bin/grep '#{name}'")
            machine.communicate.execute("#{su_cmd} /usr/sbin/svccfg -s system/identity:node setprop config/nodename=\"#{name}\"")
            machine.communicate.execute("#{su_cmd} /usr/sbin/svccfg -s system/identity:node setprop config/loopback=\"#{name}\"")
            machine.communicate.execute("#{su_cmd} /usr/sbin/svccfg -s system/identity:node refresh ")
            machine.communicate.execute("#{su_cmd} /usr/sbin/svcadm restart system/identity:node ")
          end
        end
      end
    end
  end
end
