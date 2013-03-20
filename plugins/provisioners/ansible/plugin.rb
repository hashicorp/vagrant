require "vagrant"

module VagrantPlugins
  module Ansible
    class Plugin < Vagrant.plugin("2")
      name "ansible"
      description <<-DESC
      Provides support for provisioning your virtual machines with
      Ansible playbooks.
      DESC

      config(:ansible, :provisioner) do
        require_relative "config"
        Config
      end

      provisioner(:ansible) do
        require_relative "provisioner"
        Provisioner
      end
    end
  end
end
