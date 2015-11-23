require "vagrant"

module VagrantPlugins
  module CommandAddress
    class Plugin < Vagrant.plugin("2")
      name "address"
      description <<-DESC
      The `address` command outputs public IP address of a guest machine
      DESC

      command("address", primary: false) do
        require_relative "command"
        Command
      end
    end
  end
end
