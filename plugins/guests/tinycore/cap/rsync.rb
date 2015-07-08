module VagrantPlugins
  module GuestTinyCore
    module Cap
      class RSync
        def self.rsync_install(machine)
          machine.communicate.tap do |comm|
            # Run it but don't error check because this is always failing currently
            comm.execute("tce-load -wi acl attr rsync", error_check: false)

            # Verify it by executing rsync
            comm.execute("rsync --help")
          end
        end
      end
    end
  end
end
