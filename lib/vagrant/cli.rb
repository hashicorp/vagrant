require 'thor'

module Vagrant
  class CLI < Thor
    attr_reader :env

    def initialize(args=[], options={}, config={})
      super

      # Set the UI to a shell based UI using the shell object which
      # Thor sets up.
      Vagrant.ui = UI::Shell.new(shell) if !Vagrant.ui.is_a?(UI::Shell)

      # The last argument must _always_ be a Vagrant Environment class.
      raise CLIMissingEnvironment.new("This command requires that a Vagrant environment be properly passed in as the last parameter.") if !config[:env]
      @env = config[:env]
    end
  end
end
