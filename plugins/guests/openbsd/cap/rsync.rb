module VagrantPlugins
  module GuestOpenBSD
    module Cap
      class RSync
        def self.rsync_install(machine)
          machine.communicate.sudo(
            'PKG_PATH="http://ftp.openbsd.org/pub/OpenBSD/' \
            '`uname -r`/packages/`arch -s`/" ' \
            'pkg_add -I rsync--')
        end

        def self.rsync_installed(machine)
          machine.communicate.test('which rsync')
        end

        def self.rsync_command(_machine)
          'sudo rsync'
        end

        def self.rsync_pre(machine, opts)
          machine.communicate.tap do |comm|
            comm.sudo("mkdir -p '#{opts[:guestpath]}'")
          end
        end

        def self.rsync_post(machine, opts)
          machine.communicate.sudo(
            "find '#{opts[:guestpath]}' '(' ! -user #{opts[:owner]} -or ! -group #{opts[:group]} ')' -print0 | " \
            "xargs -0 -r chown #{opts[:owner]}:#{opts[:group]}")
        end
      end
    end
  end
end
