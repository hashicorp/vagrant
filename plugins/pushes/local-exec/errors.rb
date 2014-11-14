module VagrantPlugins
  module LocalExecPush
    module Errors
      class Error < Vagrant::Errors::VagrantError
        error_namespace("local_exec_push.errors")
      end

      class CommandFailed < Error
        error_key(:command_failed)
      end
    end
  end
end
