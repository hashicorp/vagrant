require 'optparse'

module VagrantPlugins
  module CommandPush
    class Command < Vagrant.plugin("2", :command)
      def self.synopsis
        "deploys code in this environment to a configured destination"
      end

      def execute
        options = { all: false }
        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant push [strategy] [options]"
          o.on("-a", "--all", "Run all defined push strategies") do
            options[:all] = true
          end
        end

        # Parse the options
        argv = parse_options(opts)
        return if !argv

        names = validate_pushes!(@env.pushes, argv, options)

        names.each do |name|
          @logger.debug("'push' environment with strategy: `#{name}'")
          @env.push(name)
        end

        0
      end

      # Validate that the given list of names corresponds to valid pushes.
      #
      # @raise Vagrant::Errors::PushesNotDefined
      #   if there are no pushes defined
      # @raise Vagrant::Errors::PushStrategyNotProvided
      #   if there are multiple push strategies defined and none were specified
      #   and `--all` was not given
      # @raise Vagrant::Errors::PushStrategyNotDefined
      #   if any of the given push names do not correspond to a push strategy
      #
      # @param [Array<Symbol>] pushes
      #   the list of pushes defined by the environment
      # @param [Array<String>] names
      #   the list of names provided by the user on the command line
      # @param [Hash] options
      #   a list of options to pass to the validation
      #
      # @return [Array<Symbol>]
      #   the compiled list of pushes
      #
      def validate_pushes!(pushes, names = [], options = {})
        if pushes.nil? || pushes.empty?
          raise Vagrant::Errors::PushesNotDefined
        end

        names = Array(names).flatten.compact.map(&:to_sym)

        if names.empty? || options[:all]
          if options[:all] || pushes.length == 1
            return pushes.map(&:to_sym)
          else
            raise Vagrant::Errors::PushStrategyNotProvided, pushes: pushes
          end
        end

        names.each do |name|
          if !pushes.include?(name)
            raise Vagrant::Errors::PushStrategyNotDefined,
              name: name,
              pushes: pushes
          end
        end

        return names
      end
    end
  end
end
