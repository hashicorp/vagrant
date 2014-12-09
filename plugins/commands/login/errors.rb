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
    end
  end
end
