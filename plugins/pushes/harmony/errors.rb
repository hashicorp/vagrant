module VagrantPlugins
  module HarmonyPush
    module Errors
      class Error < Vagrant::Errors::VagrantError
        error_namespace("harmony_push.errors")
      end

      class UploaderNotFound < Error
        error_key(:uploader_error)
      end
    end
  end
end
