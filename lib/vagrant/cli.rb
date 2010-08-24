require 'thor'

module Vagrant
  # Entrypoint for the Vagrant CLI. This class should never be
  # initialized directly (like a typical Thor class). Instead,
  # use {Environment#cli} to invoke the CLI.
  class CLI < Thor
    # Registers the given class with the CLI so it can be accessed.
    # The class must be a subclass of either {Command} or {GroupCommand}.
    def self.register(klass, name, usage, description)
      if klass <= Thor # TODO: make Command::GroupBase
        # A subclass of Thor is a subcommand, since it contains
        # many smaller commands within it.
        desc usage, description
        subcommand name, klass
      elsif klass <= Command::Base
        # A subclass of Thor::Group is a single command, since it
        # is invoked as a whole.
        desc usage, description
        define_method(name) { |*args| invoke klass, args }
      end
    end
  end
end
