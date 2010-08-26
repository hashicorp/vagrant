require 'thor'
require 'thor/actions'

module Vagrant
  module Command
    # A {GroupBase} is the subclass which should be used if you're
    # creating a CLI command which has subcommands such as `vagrant box`,
    # which has subcommands such as `add`, `remove`, `list`. If you're
    # creating a simple command which has no subcommands, such as `vagrant up`,
    # then use {Base} instead.
    class GroupBase < Thor
      include Thor::Actions
      include Helpers

      attr_reader :env

      # Register the command with the main Vagrant CLI under the given
      # usage. The usage will be used for accessing it from the CLI,
      # so if you give it a usage of `lamp [subcommand]`, then the command
      # to invoke this will be `vagrant lamp` (with a subcommand).
      #
      # Additionally, unlike {Base}, a description must be specified to
      # this register command, since there is no class-wide description.
      def self.register(usage, description, opts=nil)
        CLI.register(self, Base.extract_name_from_usage(usage), usage, description, opts)
      end

      def initialize(*args)
        super
        initialize_environment(*args)
      end
    end
  end
end
