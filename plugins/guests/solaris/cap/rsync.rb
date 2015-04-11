module VagrantPlugins
  module GuestSolaris
    module Cap
      class RSync
        def self.rsync_installed(machine)
          machine.communicate.test("which rsync")
        end

        def self.rsync_command(machine)
          "#{machine.config.solaris.suexec_cmd} rsync"
        end

        def self.rsync_pre(machine, opts)
          machine.communicate.tap do |comm|
            comm.sudo("mkdir -p '#{opts[:guestpath]}'")
          end
        end

        def self.rsync_post(machine, opts)
          suexec_cmd = machine.config.solaris.suexec_cmd
          machine.communicate.execute(
            "#{suexec_cmd} find '#{opts[:guestpath]}' '(' ! -user #{opts[:owner]} -or ! -group #{opts[:group]} ')' -print0 | " +
            "xargs -0 chown #{opts[:owner]}:#{opts[:group]}")
        end
      end
    end
  end
end
