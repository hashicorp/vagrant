module VagrantPlugins
  module GuestCoreOS
    module Cap
      class ChangeHostName
        def self.change_host_name(machine, name)
          comm = machine.communicate

          if !comm.test("hostname -f | grep '^#{name}$'", sudo: false)
            basename = name.split(".", 2)[0]
            comm.sudo("hostname '#{basename}'")

            # Note that when working with CoreOS, we explicitly do not add the
            # entry to /etc/hosts because this file does not exist on CoreOS.
            # We could create it, but the recommended approach on CoreOS is to
            # use Fleet to manage /etc/hosts files.
          end
        end
      end
    end
  end
end
