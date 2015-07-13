module VagrantPlugins
  module GuestWindows
    module Cap
      class RSync
        def self.rsync_pre(machine, opts)
          machine.communicate.tap do |comm|
            comm.execute("mkdir '#{opts[:guestpath]}'")
          end
        end
      end
    end
  end
end
