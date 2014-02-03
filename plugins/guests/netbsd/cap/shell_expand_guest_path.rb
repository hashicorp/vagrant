module VagrantPlugins
  module GuestNetBSD
    module Cap
      class ShellExpandGuestPath
        def self.shell_expand_guest_path(machine, path)
          real_path = nil
          machine.communicate.execute("printf #{path}") do |type, data|
            if type == :stdout
              real_path ||= ""
              real_path += data
            end
          end

          if !real_path
            # If no real guest path was detected, this is really strange
            # and we raise an exception because this is a bug.
            raise ShellExpandFailed
          end

          # Chomp the string so that any trailing newlines are killed
          return real_path.chomp
        end
      end
    end
  end
end
