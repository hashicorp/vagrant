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

        name = validate_pushes!(@env.pushes, argv[0])

        # Validate the configuration
        @env.machine(@env.machine_names.first, @env.default_provider).action_raw(
          :config_validate,
          Vagrant::Action::Builtin::ConfigValidate)

        @logger.debug("'push' environment with strategy: `#{name}'")
        @env.push(name)

        0
      end

      # Validate that the given list of names corresponds to valid pushes.
      #
      # @raise Vagrant::Errors::PushesNotDefined
      #   if there are no pushes defined
      # @raise Vagrant::Errors::PushStrategyNotProvided
      #   if there are multiple push strategies defined and none were specified
      # @raise Vagrant::Errors::PushStrategyNotDefined
      #   if the given push name do not correspond to a push strategy
      #
      # @param [Array<Symbol>] pushes
      #   the list of pushes defined by the environment
      # @param [String] name
      #   the name provided by the user on the command line
      #
      # @return [Symbol]
      #   the compiled list of pushes
      #
      def validate_pushes!(pushes, name = nil)
        if pushes.nil? || pushes.empty?
          raise Vagrant::Errors::PushesNotDefined
        end

        if name.nil?
          if pushes.length == 1
            return pushes.first.to_sym
          else
            raise Vagrant::Errors::PushStrategyNotProvided,
              pushes: pushes.map(&:to_s)
          end
        end

        name = name.to_sym
        if !pushes.include?(name)
          raise Vagrant::Errors::PushStrategyNotDefined,
            name: name.to_s,
            pushes: pushes.map(&:to_s)
        end

        return name
      end
    end
  end
end
