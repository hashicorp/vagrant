require_relative "../docker/config"

module VagrantPlugins
  module PodmanProvisioner
    class Config < VagrantPlugins::DockerProvisioner::Config
      def post_install_provision(name, **options, &block)
        # Abort
        raise PodmanError, :wrong_provisioner if options[:type] == "podman"

        proxy = VagrantPlugins::Kernel_V2::VMConfig.new
        proxy.provision(name, **options, &block)
        @post_install_provisioner = proxy.provisioners.first
      end
    end
  end
end
