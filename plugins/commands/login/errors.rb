module VagrantPlugins
  module LoginCommand
    module Errors
      class Error < Vagrant::Errors::VagrantError
        error_namespace("login_command.errors")
      end

      class ServerError < Error
        error_key(:server_error)
      end

      class ServerUnreachable < Error
        error_key(:server_unreachable)
      end

      class Unauthorized < Error
        error_key(:unauthorized)
      end

      class TwoFactorRequired < Error
      end
    end
  end
end
