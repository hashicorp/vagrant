module Vagrant
  module Guest
    class Linux < Vagrant::Guest::Base
      class LinuxError < Errors::VagrantError
        error_namespace("vagrant.guest.linux")
      end
    end
  end
end
