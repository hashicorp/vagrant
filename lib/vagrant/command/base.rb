require 'thor/group'
require 'thor/actions'

module Vagrant
  module Command
    # A {Base} is the superclass for all commands which are single
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
    # view the various Vagrant commands, which are relatively simple, and
    # can be found in the Vagrant source tree at `lib/vagrant/command/`.
    #
    # # Defining a New Command
    #
    # To define a new single command, create a new class which inherits
    # from this class, then call {register} to register the command. That's
    # it! When the command is invoked, _all public methods_ will be called.
    # Below is an example `SayHello` class:
    #
    #     class SayHello < Vagrant::Command::Base
    #       register "hello", "Says hello"
    #
    #       def hello
    #         env.ui.info "Hello"
    #       end
    #     end
    #
    # In this case, the above class is invokable via `vagrant hello`. To give
    # this a try, just copy and paste the above into a Vagrantfile somewhere.
    # The command will be available for that project!
    #
    # Also note that the above example uses `env.ui` to output. It is recommended
    # you use this instead of raw "puts" since it is configurable and provides
    # additional functionality, such as colors and asking for user input. See
    # the {UI} class for more information.
    #
    # ## Defining Command-line Options
    #
    # Most command line actions won't be as simple as `vagrant hello`, and will
    # probably require parameters or switches. Luckily, Thor makes adding these
    # easy:
    #
    #     class SayHello < Vagrant::Command::Base
    #       register "hello", "Says hello"
    #       argument :name, :type => :string
    #
    #       def hello
    #         env.ui.info "Hello, #{name}"
    #       end
    #     end
    #
    # Then, the above can be invoked with `vagrant hello Mitchell` which would
    # output "Hello, Mitchell." If instead you're looking for switches, such as
    # "--name Mitchell", then take a look at `class_option`, an example of which
    # can be found in the {PackageCommand}.
    class Base < Thor::Group
      include Thor::Actions
      include Helpers

      attr_reader :env

      # Register the command with the main Vagrant CLI under the
      # given name. The name will be used for accessing it from the CLI,
      # so if you name it "lamp", then the command to invoke this
      # will be `vagrant lamp`.
      #
      # The description is used when the help is listed, and is meant to be
      # a brief (one sentence) description of what the command does.
      #
      # Some additional options may be passed in as the last parameter:
      #
      # * `:alias` - If given as an array or string, these will be aliases
      #  for the same command. For example, `vagrant version` is also
      #  `vagrant --version` and `vagrant -v`
      #
      # @param [String] usage
      # @param [String] description
      # @param [Hash] opts
      def self.register(usage, description, opts=nil)
        desc description
        CLI.register(self, extract_name_from_usage(usage), usage, desc, opts)
      end

      def initialize(*args)
        super
        initialize_environment(*args)
      end

      protected

      # Extracts the name of the command from a usage string. Example:
      # `init [box_name] [box_url]` becomes just `init`.
      def self.extract_name_from_usage(usage)
        /^([-_a-zA-Z0-9]+)(\s+(.+?))?$/.match(usage).to_a[1]
      end
    end
  end
end
