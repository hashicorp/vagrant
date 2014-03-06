module VagrantPlugins
  module CommandRdp
    class Plugin < Vagrant.plugin("2")
      name "rdp command"
      description <<-DESC
      The `rdp` command generates a .rdp file for the current Virtual Machine,
      with necessary resoruces shared from the host. This command is an alternate for
      vagrant ssh for windows Virtual Machines
      DESC

      command("rdp") do
        require File.expand_path("../command", __FILE__)
        Command
      end
    end
  end
end
