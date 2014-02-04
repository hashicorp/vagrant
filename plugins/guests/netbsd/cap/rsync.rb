module VagrantPlugins
  module GuestNetBSD
    module Cap
      class RSync
        def self.rsync_installed(machine)
          machine.communicate.test("which rsync")
        end

        def self.rsync_install(machine)
          machine.communicate.sudo(
            'PKG_PATH="http://ftp.NetBSD.org/pub/pkgsrc/packages/NetBSD/' \
            '`uname -m`/`uname -r | cut -d. -f1-2`/All" ' \
            'pkg_add rsync')
        end

        def self.rsync_pre(machine, folder_opts)
          username = machine.ssh_info[:username]

          machine.communicate.tap do |comm|
            comm.sudo("mkdir -p '#{folder_opts[:guestpath]}'")
            comm.sudo("chown -R #{username} '#{folder_opts[:guestpath]}'")
          end
        end
      end
    end
  end
end
