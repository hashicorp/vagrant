module VagrantPlugins
  module CloudCommand
    module Errors
      class Error < Vagrant::Errors::VagrantError
        error_namespace("cloud_command.errors")
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

      class Unexpected < Error
        error_key(:unexpected_error)
      end

      class TwoFactorRequired < Error
      end
    end
  end
end
