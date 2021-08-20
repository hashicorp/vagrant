module VagrantPlugins
  module CommandServe
    module Client
      # Simple alias
      Empty = Google::Protobuf::Empty
      SDK = Service::SDK
      SRV = Service::SRV
      ServiceInfo = Service::ServiceInfo

      autoload :Guest, Vagrant.source_root.join("plugins/commands/serve/client/guest").to_s
      autoload :Machine, Vagrant.source_root.join("plugins/commands/serve/client/machine").to_s
      autoload :TargetIndex, Vagrant.source_root.join("plugins/commands/serve/client/target_index").to_s
      autoload :Project, Vagrant.source_root.join("plugins/commands/serve/client/project").to_s
      autoload :Target, Vagrant.source_root.join("plugins/commands/serve/client/target").to_s
      autoload :Terminal, Vagrant.source_root.join("plugins/commands/serve/client/terminal").to_s
    end
  end
end
