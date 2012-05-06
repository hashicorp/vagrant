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

    # This creates a new easy hook. This should not be called by the
    # general public. Instead, use the plugin interface.
    #
    # @return [Proc]
    def self.create_hook(&block)
      # Create a lambda which simply calls the plugin with the operations
      lambda do |env|
        ops = Operations.new(env[:vm])
        block.call(ops)
      end
    end
  end
end
