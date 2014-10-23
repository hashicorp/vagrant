require 'optparse'

module VagrantPlugins
  module CommandPush
    class Command < Vagrant.plugin("2", :command)
      def self.synopsis
        "deploys code in this environment to a configured destination"
      end

      # @todo support multiple strategies if requested by the community
      def execute
        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant push [strategy] [options]"
        end

        # Parse the options
        argv = parse_options(opts)
        return if !argv

        name = argv[0]
        pushes = @env.pushes

        # TODO: this logic is 100% duplicated in Enviroment#push - should we
        # just not validate here?
        validate_pushes!(pushes, name)

        @logger.debug("'push' environment with strategy: `#{name}'")
        @env.push(name)

        0
      end

      # Validate that the given list of pushes and strategy are valid.
      #
      # @raise [PushesNotDefined] if there are no pushes defined for the
      #   environment
      # @raise [PushStrategyNotDefined] if a strategy is given, but does not
      #   correspond to one that exists in the environment
      #
      # @param [Registry] pushes The list of pushes as a {Registry}
      # @param [#to_sym, nil] name The name of the strategy
      #
      # @return [true]
      def validate_pushes!(pushes, name=nil)
        if pushes.nil? || pushes.empty?
          raise Vagrant::Errors::PushesNotDefined
        end

        if name.nil?
          if pushes.length != 1
            raise Vagrant::Errors::PushStrategyNotProvided, pushes: pushes
          end
        else
          if !pushes.key?(name.to_sym)
            raise Vagrant::Errors::PushStrategyNotDefined,
              name: name,
              pushes: pushes
          end
        end

        true
      end
    end
  end
end
