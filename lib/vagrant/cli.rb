require 'thor'

module Vagrant
  # Entrypoint for the Vagrant CLI. This class should never be
  # initialized directly (like a typical Thor class). Instead,
  # use {Environment#cli} to invoke the CLI.
  #
  # # Defining Custom CLI Commands
  #
  # If you're looking to define custom CLI commands, then look at
  # one of the two following classes:
  #
  # * {Command::Base} - Implementing a single command such as `vagrant up`, e.g.
  #   one without subcommands. Also take a look at {Command::NamedBase}.
  # * {Command::GroupBase} - Implementing a command with subcommands, such as
  #   `vagrant box`, which has the `list`, `add`, etc. subcommands.
  #
  # The above linked classes contain the main documentation for each
  # type of command.
  class CLI < Thor
    # Registers the given class with the CLI so it can be accessed.
    # The class must be a subclass of either {Command::Base} or {Command::GroupBase}.
    # Don't call this method directly, instead call the {Command::Base.register}
    # or {Command::GroupBase.register} methods.
    #
    # @param [Class] klass Command class
    # @param [String] name Command name, accessed at `vagrant NAME`
    # @param [String] usage Command usage, such as "vagrant NAME [--option]"
    # @param [String] description Description of the command shown during the
    #   command listing.
    # @param [Hash] opts Other options (not gone into detail here, look at
    #   the source instead).
    def self.register(klass, name, usage, description, opts=nil)
      opts ||= {}

      if klass <= Command::GroupBase
        # A subclass of GroupBase is a subcommand, since it contains
        # many smaller commands within it.
        desc usage, description, opts
        subcommand name, klass
      elsif klass <= Command::Base
        # A subclass of Base is a single command, since it
        # is invoked as a whole (as Thor::Group)
        desc usage, description, opts
        define_method(name) { |*args| invoke klass, args }
      end

      if opts[:alias]
        # Alises are defined for this command, so properly alias the
        # newly defined method/subcommand:
        map opts[:alias] => name
      end
    end
  end
end
