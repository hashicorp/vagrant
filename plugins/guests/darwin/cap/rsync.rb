module VagrantPlugins
  module GuestDarwin
    module Cap
      class RSync
        def self.rsync_installed(machine)
          machine.communicate.test("which rsync")
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
          if opts.key?(:chown) && !opts[:chown]
            return
          end

          machine.communicate.sudo(
            "find '#{opts[:guestpath]}' '(' ! -user #{opts[:owner]} -or ! -group #{opts[:group]} ')' -print0 | " +
            "xargs -0 chown #{opts[:owner]}:#{opts[:group]}")
        end
      end
    end
  end
end
