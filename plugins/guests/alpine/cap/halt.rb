# rubocop:disable Style/RedundantBegin
# rubocop:disable Lint/HandleExceptions
#
# FIXME: address disabled warnings
#
module VagrantPlugins
  module GuestAlpine
    module Cap
      class Halt
        def self.halt(machine)
          begin
            machine.communicate.sudo('poweroff')
          rescue Net::SSH::Disconnect, IOError
            # Ignore, this probably means connection closed because it
            # shut down and SSHd was stopped.
          end
        end
      end
    end
  end
end
