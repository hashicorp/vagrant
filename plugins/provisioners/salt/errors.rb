require "vagrant"

module VagrantPlugins
  module Salt
    module Errors
      class SaltError < Vagrant::Errors::VagrantError
        error_namespace("vagrant.provisioners.salt")
      end
    end
  end
end