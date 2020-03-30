require_relative "client"
require_relative "installer"

module VagrantPlugins
  module ContainerProvisioner
    class Provisioner < Vagrant.plugin("2", :provisioner)
      def initialize(machine, config, installer = nil, client = nil)
        super(machine, config)

        @installer = installer || Installer.new(@machine)
        @client    = client    || Client.new(@machine, "")
        @logger = Log4r::Logger.new("vagrant::provisioners::container")
      end

      def provision
        # nothing to do
      end

      def run_provisioner(env)
        klass  = Vagrant.plugin("2").manager.provisioners[env[:provisioner].type]
        result = klass.new(env[:machine], env[:provisioner].config)
        result.config.finalize!

        result.provision
      end
    end
  end
end
