require_relative "../container/config"

module VagrantPlugins
  module DockerProvisioner
    class Config < VagrantPlugins::ContainerProvisioner::Config
      def post_install_provision(name, **options, &block)
        # Abort
        raise DockerError, :wrong_provisioner if options[:type] == "docker"

        proxy = VagrantPlugins::Kernel_V2::VMConfig.new
        proxy.provision(name, **options, &block)
        @post_install_provisioner = proxy.provisioners.first
      end
    end
  end
end
