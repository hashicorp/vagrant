module Vagrant
  module Easy
    autoload :CommandBase, "vagrant/easy/command_base"
    autoload :Operations,  "vagrant/easy/operations"

    # This creates a new easy command. This typically is not called
    # directly. Instead, the plugin interface's `easy_command` is
    # used to create one of these.
    def self.create_command(name, &block)
      # Create a new command class for this command, and return it
      command = Class.new(CommandBase)
      command.configure(name, &block)
      command
    end
  end
end
