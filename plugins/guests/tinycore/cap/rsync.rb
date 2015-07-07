module VagrantPlugins
  module GuestTinyCore
    module Cap
      class RSync
        def self.rsync_install(machine)
          machine.communicate.tap do |comm|
            # do not sudo tce-load
            comm.execute("tce-load -wi acl attr rsync")
          end
        end
      end
    end
  end
end
