module VagrantPlugins
  module CommandServe
    module Client
      autoload :Box, Vagrant.source_root.join("plugins/commands/serve/client/box").to_s
      autoload :BoxCollection, Vagrant.source_root.join("plugins/commands/serve/client/box_collection").to_s
      autoload :CapabilityPlatform, Vagrant.source_root.join("plugins/commands/serve/client/capability_platform").to_s
      autoload :Guest, Vagrant.source_root.join("plugins/commands/serve/client/guest").to_s
      autoload :Host, Vagrant.source_root.join("plugins/commands/serve/client/host").to_s
      autoload :TargetIndex, Vagrant.source_root.join("plugins/commands/serve/client/target_index").to_s
      autoload :Project, Vagrant.source_root.join("plugins/commands/serve/client/project").to_s
      autoload :Target, Vagrant.source_root.join("plugins/commands/serve/client/target").to_s
      autoload :Terminal, Vagrant.source_root.join("plugins/commands/serve/client/terminal").to_s
      autoload :StateBag, Vagrant.source_root.join("plugins/commands/serve/client/state_bag").to_s      
      autoload :SyncedFolder, Vagrant.source_root.join("plugins/commands/serve/client/synced_folder").to_s
    end
  end
end
