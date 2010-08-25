require 'thor/group'
require 'thor/actions'

module Vagrant
  module Command
    # A CLI command is the subclass for all commands which are single
    # commands, e.g. `vagrant init`, `vagrant up`. Not commands like
    # `vagrant box add`. For commands which have more subcommands, use
    # a {GroupBase}.
    #
    # A {Base} is a subclass of `Thor::Group`, so view the documentation
    # there on how to add arguments, descriptions etc. The important note
    # about this is that when invoked, _all public methods_ will be called
    # in the order they are defined. If you don't want a method called when
    # the command is invoked, it must be made `protected` or `private`.
    #
    # The best way to get examples of how to create your own command is to
    # view the various Vagrant commands, which are relatively simple.
    class Base < Thor::Group
      include Thor::Actions
      include Helpers

      attr_reader :env

      # Register the command with the main Vagrant CLI under the
      # given name. The name will be used for accessing it from the CLI,
      # so if you name it "lamp", then the command to invoke this
      # will be `vagrant lamp`.
      #
      # The description added to the class via the `desc` method will be
      # used as a description for the command.
      def self.register(usage, opts=nil)
        CLI.register(self, extract_name_from_usage(usage), usage, desc, opts)
      end

      # Extracts the name of the command from a usage string. Example:
      # `init [box_name] [box_url]` becomes just `init`.
      def self.extract_name_from_usage(usage)
        /^([-_a-zA-Z0-9]+)(\s+(.+?))?$/.match(usage).to_a[1]
      end

      def initialize(args=[], options={}, config={})
        super

        # The last argument must _always_ be a Vagrant Environment class.
        raise CLIMissingEnvironment.new("This command requires that a Vagrant environment be properly passed in as the last parameter.") if !config[:env]
        @env = config[:env]
        @env.ui = UI::Shell.new(shell) if !@env.ui.is_a?(UI::Shell)
      end
    end
  end
end
