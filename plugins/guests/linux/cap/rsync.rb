require "shellwords"

module VagrantPlugins
  module GuestLinux
    module Cap
      class RSync
        def self.rsync_installed(machine)
          machine.communicate.test("which rsync")
        end

        def self.rsync_command(machine)
          "sudo rsync"
        end

        def self.rsync_pre(machine, opts)
          guest_path = Shellwords.escape(opts[:guestpath])
          machine.communicate.sudo("mkdir -p #{guest_path}")
        end

        def self.rsync_post(machine, opts)
          if opts.key?(:chown) && !opts[:chown]
            return
          end

          guest_path = Shellwords.escape(opts[:guestpath])

          machine.communicate.sudo(
            "find #{guest_path} " +
            "'!' -type l -a " +
            "'(' ! -user #{opts[:owner]} -or ! -group #{opts[:group]} ')' -print0 | " +
            "xargs -0 -r chown #{opts[:owner]}:#{opts[:group]}")
        end
      end
    end
  end
end
