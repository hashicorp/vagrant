module VagrantPlugins
  module GuestSolaris11
    module Cap
      class RSync
        def self.rsync_installed(machine)
          machine.communicate.test("which rsync")
        end

        def self.rsync_command(machine)
          "#{machine.config.solaris11.suexec_cmd} rsync"
        end

        def self.rsync_post(machine, opts)
          su_cmd = machine.config.solaris11.su_cmd
          machine.communicate.execute(
            "#{su_cmd} '#{opts[:guestpath]}' '(' ! -user #{opts[:owner]} -or ! -group #{opts[:group]} ')' -print0 | " +
              "xargs -0 -r chown -v #{opts[:owner]}:#{opts[:group]}")
        end
      end
    end
  end
end
