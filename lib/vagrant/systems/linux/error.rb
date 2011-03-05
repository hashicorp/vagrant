module Vagrant
  module Systems
    class Linux < Vagrant::Systems::Base
      class LinuxError < Errors::VagrantError
        error_namespace("vagrant.systems.linux")
      end
    end
  end
end
