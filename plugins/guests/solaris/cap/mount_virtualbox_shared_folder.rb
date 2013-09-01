module VagrantPlugins
  module GuestSolaris
    module Cap
      class MountVirtualBoxSharedFolder
        def self.mount_virtualbox_shared_folder(machine, name, guestpath, options)
          # These are just far easier to use than the full options syntax
          owner = options[:owner]
          group = options[:group]

          # Create the shared folder
          machine.communicate.execute("#{machine.config.solaris.suexec_cmd} mkdir -p #{guestpath}")

          # We have to use this `id` command instead of `/usr/bin/id` since this
          # one accepts the "-u" and "-g" flags.
          id_cmd        = "/usr/xpg4/bin/id"

          # Mount the folder with the proper owner/group
          mount_options = "-o uid=`#{id_cmd} -u #{owner}`,gid=`#{id_cmd} -g #{group}`"
          if options[:mount_options]
            mount_options += ",#{options[:mount_options].join(",")}"
          end

          machine.communicate.execute("#{machine.config.solaris.suexec_cmd} /sbin/mount -F vboxfs #{mount_options} #{name} #{guestpath}")

          # chown the folder to the proper owner/group
          machine.communicate.execute("#{machine.config.solaris.suexec_cmd} chown `#{id_cmd} -u #{owner}`:`#{id_cmd} -g #{group}` #{guestpath}")
        end
      end
    end
  end
end
