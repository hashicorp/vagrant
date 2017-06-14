module VagrantPlugins
  module GuestWindows
    module Cap
      class RSync
        def self.rsync_scrub_guestpath( machine, opts )
          # Windows guests most often use cygwin-dependent rsync utilities
          # that expect "/cygdrive/c" instead of "c:" as the path prefix
          # some vagrant code may pass guest paths with drive-lettered paths here
          opts[:guestpath].gsub( /^([a-zA-Z]):/, '/cygdrive/\1' )
        end

        def self.rsync_pre(machine, opts)
          machine.communicate.tap do |comm|
            # rsync does not construct any gaps in the path to the target directory
            # make sure that all subdirectories are created
            comm.execute("mkdir -p '#{opts[:guestpath]}'")
          end
        end
      end
    end
  end
end
