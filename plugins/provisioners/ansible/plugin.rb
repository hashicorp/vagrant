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
        require File.expand_path("../config", __FILE__)
        Config
      end

      provisioner(:ansible) do
        require File.expand_path("../provisioner", __FILE__)
        Provisioner
      end
    end
  end
end
