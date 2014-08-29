module VagrantPlugins
  module GuestSmartos
    module Cap
      class RSync
        def self.rsync_installed(machine)
          machine.communicate.test("which rsync")
        end

        def self.rsync_command(machine)
          "#{machine.config.smartos.suexec_cmd} rsync"
        end

        def self.rsync_pre(machine, opts)
          machine.communicate.tap do |comm|
            comm.execute("#{machine.config.smartos.suexec_cmd} mkdir -p '#{opts[:guestpath]}'")
          end
        end

        def self.rsync_post(machine, opts)
          machine.communicate.execute("#{machine.config.smartos.suexec_cmd} find '#{opts[:guestpath]}' '(' ! -user #{opts[:owner]} -or ! -group #{opts[:group]} ')' -print0 | " +
              "#{machine.config.smartos.suexec_cmd} xargs -0 chown #{opts[:owner]}:#{opts[:group]}")
        end
      end
    end
  end
end
