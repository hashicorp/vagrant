module VagrantPlugins
  module DockerProvider
    autoload :Action, File.expand_path("../action", __FILE__)
    autoload :Driver, File.expand_path("../driver", __FILE__)
    autoload :Errors, File.expand_path("../errors", __FILE__)

    module Executor
      autoload :Local, File.expand_path("../executor/local", __FILE__)
      autoload :Vagrant, File.expand_path("../executor/vagrant", __FILE__)
    end

    class Plugin < Vagrant.plugin("2")
      name "docker-provider"
      description <<-EOF
      The Docker provider allows Vagrant to manage and control
      Docker containers.
      EOF

      provider(:docker, box_optional: true, parallel: true, defaultable: false) do
        require_relative 'provider'
        init!
        Provider
      end

      command("docker-logs", primary: false) do
        require_relative "command/logs"
        init!
        Command::Logs
      end

      command("docker-run", primary: false) do
        require_relative "command/run"
        init!
        Command::Run
      end

      communicator(:docker_hostvm) do
        require_relative "communicator"
        init!
        Communicator
      end

      config(:docker, :provider) do
        require_relative 'config'
        init!
        Config
      end

      synced_folder(:docker) do
        require File.expand_path("../synced_folder", __FILE__)
        SyncedFolder
      end

      provider_capability("docker", "public_address") do
        require_relative "cap/public_address"
        Cap::PublicAddress
      end

      provider_capability("docker", "proxy_machine") do
        require_relative "cap/proxy_machine"
        Cap::ProxyMachine
      end

      protected

      def self.init!
        return if defined?(@_init)
        I18n.load_path << File.expand_path(
          "templates/locales/providers_docker.yml", Vagrant.source_root)
        I18n.reload!
        @_init = true
      end
    end
  end
end
