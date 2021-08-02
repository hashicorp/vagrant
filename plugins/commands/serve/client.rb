module VagrantPlugins
  module CommandServe
    module Client
      # Simple alias
      SDK = Service::SDK
      SRV = Service::SRV
      ServiceInfo = Service::ServiceInfo

      autoload :Machine, Vagrant.source_root.join("plugins/commands/serve/client/machine").to_s
      autoload :Project, Vagrant.source_root.join("plugins/commands/serve/client/project").to_s
      autoload :Terminal, Vagrant.source_root.join("plugins/commands/serve/client/terminal").to_s
      autoload :MachineIndex, Vagrant.source_root.join("plugins/commands/serve/client/machine_index").to_s
    end
  end
end
