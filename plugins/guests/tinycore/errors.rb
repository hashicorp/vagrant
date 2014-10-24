module VagrantPlugins
  module GuestTinyCore
    module Errors
      class TinyCoreError < Vagrant::Errors::VagrantError
        error_namespace("vagrant_tinycore.errors")
      end

      class NetworkStaticOnly < TinyCoreError
        error_key(:network_static_only)
      end
    end
  end
end
