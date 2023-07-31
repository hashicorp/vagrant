# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    class Client
      autoload :Basis, Vagrant.source_root.join("plugins/commands/serve/client/basis").to_s
      autoload :Box, Vagrant.source_root.join("plugins/commands/serve/client/box").to_s
      autoload :BoxCollection, Vagrant.source_root.join("plugins/commands/serve/client/box_collection").to_s
      autoload :BoxMetadata, Vagrant.source_root.join("plugins/commands/serve/client/box_metadata").to_s
      autoload :CapabilityPlatform, Vagrant.source_root.join("plugins/commands/serve/client/capability_platform").to_s
      autoload :Communicator, Vagrant.source_root.join("plugins/commands/serve/client/communicator").to_s
      autoload :Command, Vagrant.source_root.join("plugins/commands/serve/client/command").to_s
      autoload :CorePluginManager, Vagrant.source_root.join("plugins/commands/serve/client/core_plugin_manager").to_s
      autoload :Guest, Vagrant.source_root.join("plugins/commands/serve/client/guest").to_s
      autoload :Host, Vagrant.source_root.join("plugins/commands/serve/client/host").to_s
      autoload :TargetIndex, Vagrant.source_root.join("plugins/commands/serve/client/target_index").to_s
      autoload :PluginManager, Vagrant.source_root.join("plugins/commands/serve/client/plugin_manager").to_s
      autoload :Project, Vagrant.source_root.join("plugins/commands/serve/client/project").to_s
      autoload :Provider, Vagrant.source_root.join("plugins/commands/serve/client/provider").to_s
      autoload :Provisioner, Vagrant.source_root.join("plugins/commands/serve/client/provisioner").to_s
      autoload :Push, Vagrant.source_root.join("plugins/commands/serve/client/push").to_s
      autoload :Target, Vagrant.source_root.join("plugins/commands/serve/client/target").to_s
      autoload :Terminal, Vagrant.source_root.join("plugins/commands/serve/client/terminal").to_s
      autoload :StateBag, Vagrant.source_root.join("plugins/commands/serve/client/state_bag").to_s
      autoload :SyncedFolder, Vagrant.source_root.join("plugins/commands/serve/client/synced_folder").to_s
      autoload :Vagrantfile, Vagrant.source_root.join("plugins/commands/serve/client/vagrantfile").to_s

      prepend Util::ClientSetup
      include Util::HasLogger
      include Util::HasSeeds::Client
      include Util::HasMapper
      include Util::NamedPlugin::Client
      include Util::FuncSpec::Client

      def cache
        CommandServe.cache
      end
    end
  end
end
