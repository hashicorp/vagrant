module VagrantPlugins
  module HostDarwin
    module Errors
      # A convenient superclass for all our errors.
      class HostDarwinError < Vagrant::Errors::VagrantError
        error_namespace("host_darwin.errors")
      end

      class SudoCommandFailed < HostDarwinError
        error_key(:sudo_command_failed)
      end

      class WrongUser < HostDarwinError
        error_key(:wrong_user)
      end
    end
  end
end
