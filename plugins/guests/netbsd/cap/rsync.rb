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

        def self.rsync_command(machine)
          "sudo rsync"
        end

        def self.rsync_pre(machine, opts)
          machine.communicate.tap do |comm|
            comm.sudo("mkdir -p '#{opts[:guestpath]}'")
          end
        end

        def self.rsync_post(machine, opts)
          machine.communicate.sudo(
            "find '#{opts[:guestpath]}' '(' ! -user #{opts[:owner]} -or ! -group #{opts[:group]} ')' -print0 | " +
            "xargs -0 -r chown #{opts[:owner]}:#{opts[:group]}")
        end
      end
    end
  end
end
