require "digest/sha2"

module VagrantPlugins
  module CommandServe
    # Provides value mapping to ease interaction
    # with protobuf and clients
    class Mappers
      DEFAULT_MAPS = {
        Client::Project => Vagrant::Environment,
        Client::Target => Vagrant::Machine,
        Client::Terminal => Vagrant::UI::Remote,
        Client::SyncedFolder => Vagrant::Plugin::V2::SyncedFolder,
        SDK::Args::Array => Array,
        SDK::Args::Direct => Type::Direct,
        SDK::Args::Guest => Client::Guest,
        SDK::Args::Hash => Hash,
        SDK::Args::Host => Client::Host,
        SDK::Args::NamedCapability => Symbol,
        SDK::Args::Path => Pathname,
        SDK::Args::Project => Vagrant::Environment,
        SDK::Args::Provider => Client::Provider,
        SDK::Args::StateBag => Client::StateBag,
        SDK::Args::SyncedFolder => Vagrant::Plugin::V2::SyncedFolder,
        SDK::Args::Target => Vagrant::Machine,
        SDK::Args::TargetIndex => Client::TargetIndex,
        SDK::Args::Target::Machine => Vagrant::Machine,
        SDK::Args::TimeDuration => Type::Duration,
        SDK::Args::TerminalUI => Vagrant::UI::Remote,
        SDK::Command::Arguments => Type::CommandArguments,
        SDK::Command::CommandInfo => Type::CommandInfo,
        SDK::Communicator::Command => Type::CommunicatorCommandArguments,
      }
      REVERSE_MAPS = Hash[DEFAULT_MAPS.values.zip(DEFAULT_MAPS.keys)].merge(
        Vagrant::UI::Interface => SDK::Args::TerminalUI,
      )
      REVERSE_MAPS.delete_if { |k, _| !k.name.include?("::") }

      # Constant used for generating value
      GENERATE = Class.new {
        def self.to_s
          "[Value Generation]"
        end
        def to_s
          "[Value Generation]"
        end
        def inspect
          to_s
        end
      }.new.freeze

      include Util::HasLogger

      autoload :Internal, Vagrant.source_root.join("plugins/commands/serve/mappers/internal").to_s
      autoload :Mapper, Vagrant.source_root.join("plugins/commands/serve/mappers/mapper").to_s

      # @return [Array<Object>] arguments provided to all mapper calls
      attr_reader :known_arguments
      # @return [Array<Mapper>] list of mappers
      attr_reader :mappers
      # @return [Util::Cacher] cached mapped values
      attr_accessor :cacher

      # Create a new mappers instance. Any arguments provided will be
      # available to all mapper calls
      def initialize(*args)
        @known_arguments = Array(args).compact
        Mapper.generate_anys
        @mappers = Mapper.registered.map(&:new)
        @cacher = Util::Cacher.new
      end

      # Create a clone of this mappers instance
      #
      # @return [Mappers]
      def clone
        self.class.new(*known_arguments).tap do |m|
          m.cacher = cacher
          m.mappers.replace(mappers.dup)
        end
      end

      # Add an argument to be included with mapping calls
      #
      # @param v [Object] Argument value
      # @return [Object]
      def add_argument(v)
        if v.nil?
          raise TypeError,
            "Expected valid argument but received nil value"
        end
        known_arguments << v
        v
      end

      # Convert Any proto message to actual message type
      #
      # @param any [Google::Protobuf::Any]
      # @return [Google::Protobuf::MessageExts]
      def unany(any)
        type = find_type(any.type_name.split("/").last.to_s)
        any.unpack(type)
      end

      # Get const from name
      #
      # @param name [String]
      # @return [Class]
      def find_type(name)
        name.to_s.split(".").inject(Object) { |memo, n|
          c = memo.constants.detect { |mc| mc.to_s.downcase == n.to_s.downcase }
          raise NameError,
            "Failed to find constant for `#{name}'" if c.nil?
          memo.const_get(c)
        }
      end

      # Map a given value
      #
      # @param value [Object] Value to map
      # @param named [String] Named argument to prefer
      # @param to [Class] Resultant type (optional)
      # @return [Object]
      def map(value, *extra_args, named: nil, to: nil)
        extra_args = [value, *extra_args].map do |a|
          if a.is_a?(Type::NamedArgument)
            name = a.name
            a = a.value
          end
          if a.is_a?(Google::Protobuf::Any)
            non_any = unany(a)
            logger.debug("extracted any proto message #{a.class} -> #{non_any}")
            a = non_any
          end
          if name
            a = Type::NamedArgument.new(value: a, name: name)
          end
          a
        end
        value = extra_args.shift if value

        # If our destination type is an Any, mark that the final type should
        # be any and unset our destination type. This will allow us to
        # attempt to find a proper destination type using our maps and
        # then we can pack it into any Any value at the end
        if to == Google::Protobuf::Any && !value.class.ancestors.include?(Google::Protobuf::MessageExts)
          any_convert = true
          to = nil
        end

        # If we don't have a destination type provided, attempt
        # to set it using our default maps
        to = DEFAULT_MAPS[value.class] if to.nil?
        if value != GENERATE && to.nil?
          to = REVERSE_MAPS.detect do |k, v|
            logger.debug("testing TO match for #{value.class} with #{k}")
            v if value.class.ancestors.include?(k)
          end&.last
        end
        #to = REVERSE_MAPS[value.class] if to.nil?

        # If the value given is the desired type, just return the value
        return value if value != GENERATE && !to.nil? && value.is_a?(to)

        logger.debug("starting value mapping process #{value.class} -> #{to.nil? ? 'unknown' : to.inspect}")
        if value.nil? && to
          val = (extra_args + known_arguments).detect do |item|
            item.is_a?(to)
          end
          if val && val != GENERATE
            return any_convert ? Google::Protobuf::Any.pack(val) : val
          end
        end

        # NOTE: We set the cacher instance into the extra args
        # instead of adding it as a known argument so if it is
        # changed the correct instance will be used
        extra_args << cacher
        extra_args << self

        # If the provided value is a protobuf value, just return that value
        if value.is_a?(Google::Protobuf::Value)
          logger.debug("direct return of protobuf value contents - #{value.to_ruby}")
          return value.to_ruby
        end

        args = ([value] + extra_args.compact + known_arguments.compact)
        result = nil

        # For funcspec values, we want to pre-filter since they use
        # a custom validator. This will prevent invalid paths.
        if value.is_a?(SDK::FuncSpec::Value)
          map_mapper = self.clone
          valid_mappers = map_mapper.mappers.map do |m|
            next if !m.inputs.first.valid?(SDK::FuncSpec::Value) &&
              m.output.ancestors.include?(Google::Protobuf::MessageExts)
            next m if !m.inputs.first.valid?(SDK::FuncSpec::Value) ||
              m.inputs.first.valid?(value)
            logger.trace("removing mapper - invalid funcspec match - #{m}")
            nil
          end.compact
          map_mapper.mappers.replace(valid_mappers)
        elsif value.is_a?(Google::Protobuf::MessageExts)
          map_mapper = self.clone
          valid_mappers = map_mapper.mappers.map do |m|
            next if value.is_a?(m.output)
            m
          end.compact
          map_mapper.mappers.replace(valid_mappers)
        else
          map_mapper = self
        end

        # If we don't have a desired final type, test for mappers
        # that are satisfied by the arguments we have and run that
        # directly
        if to.nil?
          valid_outputs = []
          cb = lambda do |k|
            matches = map_mapper.mappers.find_all do |m|
              m.inputs.first.valid?(k)
            end
            outs = matches.map(&:output)
            to_search = outs - valid_outputs
            valid_outputs |= outs

            to_search.each do |o|
              cb.call(o)
            end
          end
          cb.call(value)

          if valid_outputs.empty?
            raise TypeError,
              "No valid mappers found for input type `#{value.class}'"
          end

          valid_outputs.reverse!
          valid_outputs.delete_if do |o|
            (value.class.ancestors.include?(Google::Protobuf::MessageExts) &&
              o.ancestors.include?(Google::Protobuf::MessageExts)) ||
              o.ancestors.include?(value.class)
          end
          last_error = nil
          valid_outputs.each do |out|
            logger.debug("attempting blind map #{value} -> #{out}")
            begin
              m_graph = Internal::Graph::Mappers.new(
                output_type: out,
                mappers: map_mapper,
                named: named,
                input_values: args,
              )
              result = m_graph.execute
              to = out
              break
            rescue => err
              logger.debug("typeless mapping failure (non-critical): #{err} (input - #{value.class} / output #{out})")
              last_error = err
            end
          end
          raise last_error if result.nil? && last_error
        else
          m_graph = Internal::Graph::Mappers.new(
            output_type: to,
            mappers: map_mapper,
            named: named,
            input_values: args,
          )
          result = m_graph.execute
        end
        logger.debug("map of #{value.class} to #{to.nil? ? 'unknown' : to.inspect} => #{result}")
        if any_convert && !result.is_a?(Google::Protobuf::Any)
          return Google::Protobuf::Any.pack(result)
        end
        result
      rescue => err
        logger.debug("mapping failed of #{value.class} to #{to.nil? ? 'unknown' : to.inspect}")
        logger.debug("#{err.class}: #{err}\n" + err.backtrace.join("\n"))
        raise
      end

      # Generate the given type based on given and/or
      # added arguments
      def generate(*args, named: nil, type:)
        map(GENERATE, *args, named: named, to: type)
      end

      # Map values provided by a FuncSpec request into
      # actual values
      #
      # @param spec [SDK::FuncSpec::Spec]
      # @param expect [Array<Class>] Expected types for each argument
      # @return [Array<Object>, Object]
      def funcspec_map(spec, *extra_args, expect: [])
        expect = Array(expect)
        args = spec.args.dup
        # NOTE: the spec will have the order of the arguments
        # shifted one. not sure why, but we can just work around
        # it here for now.
        args.push(args.shift)

        # Start with unpacking the funcspec values so the #map method can
        # apply known default expectations to values
        args = args.map { |a| unfuncspec(a) }

        # Now send the arguments through the mapping process
        result = Array.new.tap do |result_args|
          args.each_with_index do |arg, i|
            logger.debug("mapping funcspec value #{arg.inspect} to expected type #{expect[i]}")
            result_args << map(arg, *(extra_args + result_args), to: expect[i])
          end
        end
        if result.size == 1
          return result.first
        end
        result
      end

      # Extracts proto message from funcspec argument proto
      #
      # @param v [SDK::FuncSpec::Value]
      # @return [Google:Protobuf::MessageExts]
      def unfuncspec(v)
        m = mappers.find_all { |map|
          map.inputs.size == 1 &&
            map.output.ancestors.include?(Google::Protobuf::MessageExts) &&
            map.inputs.first.valid?(v)
        }
        if m.size > 1
          raise TypeError,
            "FuncSpec value of type `#{v.class}' matches more than one mapper (#{v})"
        end
        if m.empty?
          raise ArgumentError,
            "FuncSpec value of type `#{v.class}' has no valid mappers"
        end
        result = m.first.call(v)
        logger.trace("converted funcspec argument #{v} -> #{result}")
        result
      end
    end
  end
end

# NOTE: Always directly load mappers so they are automatically registered and
#       available. Using autoloading behavior will result in them being unavailable
#       until explicitly requested by name
require Vagrant.source_root.join("plugins/commands/serve/mappers/basis.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/box.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/capabilities.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/command.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/communicator.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/direct.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/duration.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/environment.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/guest.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/host.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/known_types.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/machine.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/options.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/pathname.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/plugin_manager.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/project.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/provider.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/push.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/state_bag.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/synced_folder.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/target.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/target_index.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/terminal.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/ui.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/wrappers.rb").to_s
