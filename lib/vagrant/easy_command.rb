module Vagrant
  module EasyCommand
    autoload :Base,       "vagrant/easy_command/base"
    autoload :Operations, "vagrant/easy_command/operations"

    # This creates a new easy command. This typically is not called
    # directly. Instead, the plugin interface's `easy_command` is
    # used to create one of these.
    def self.create(name, &block)
      # Create a new command class for this command, and return it
      command = Class.new(Base)
      command.configure(name, &block)
      command
    end
  end
end
