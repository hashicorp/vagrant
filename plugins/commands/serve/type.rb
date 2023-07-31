# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    class Type
      autoload :Boolean, Vagrant.source_root.join("plugins/commands/serve/type/boolean").to_s
      autoload :CommandArguments, Vagrant.source_root.join("plugins/commands/serve/type/command_arguments").to_s
      autoload :CommunicatorCommandArguments, Vagrant.source_root.join("plugins/commands/serve/type/communicator_command_arguments").to_s
      autoload :CommandInfo, Vagrant.source_root.join("plugins/commands/serve/type/command_info").to_s
      autoload :Direct, Vagrant.source_root.join("plugins/commands/serve/type/direct").to_s
      autoload :Duration, Vagrant.source_root.join("plugins/commands/serve/type/duration").to_s
      autoload :Folders, Vagrant.source_root.join("plugins/commands/serve/type/folders").to_s
      autoload :Options, Vagrant.source_root.join("plugins/commands/serve/type/options").to_s
      autoload :NamedArgument, Vagrant.source_root.join("plugins/commands/serve/type/named_argument").to_s
      autoload :SSHInfo, Vagrant.source_root.join("plugins/commands/serve/type/ssh_info").to_s
      autoload :WinrmInfo, Vagrant.source_root.join("plugins/commands/serve/type/winrm_info").to_s

      attr_accessor :value

      def initialize(value: nil)
        @value = value
      end
    end
  end
end
