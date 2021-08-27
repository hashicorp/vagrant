module VagrantPlugins
  module CommandServe
    module Client
      autoload :CapabilityPlatform, Vagrant.source_root.join("plugins/commands/serve/client/capability_platform").to_s
      autoload :Guest, Vagrant.source_root.join("plugins/commands/serve/client/guest").to_s
      autoload :Host, Vagrant.source_root.join("plugins/commands/serve/client/host").to_s
      autoload :Machine, Vagrant.source_root.join("plugins/commands/serve/client/machine").to_s
      autoload :TargetIndex, Vagrant.source_root.join("plugins/commands/serve/client/target_index").to_s
      autoload :Project, Vagrant.source_root.join("plugins/commands/serve/client/project").to_s
      autoload :Target, Vagrant.source_root.join("plugins/commands/serve/client/target").to_s
      autoload :Terminal, Vagrant.source_root.join("plugins/commands/serve/client/terminal").to_s
    end
  end
end
