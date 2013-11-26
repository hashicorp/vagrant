module VagrantPlugins
  module Docker
    module Errors
      class DockerInstallFailed < ::Vagrant::Errors::VagrantError
      end

      class DockerNotRunning < ::Vagrant::Errors::VagrantError
      end
    end
  end
end
