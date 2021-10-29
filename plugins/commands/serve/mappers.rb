require "digest/sha2"

module VagrantPlugins
  module CommandServe
    # Provides value mapping to ease interaction
    # with protobuf and clients
    class Mappers
      DEFAULT_MAPS = {
        SDK::Args::Array => Array,
        SDK::Args::Direct => Types::Direct,
        SDK::Args::Guest => Client::Guest,
        SDK::Args::Hash => Hash,
        SDK::Args::Host => Client::Host,
        SDK::Args::NamedCapability => Symbol,
        SDK::Args::Path => Pathname,
        SDK::Args::Project => Vagrant::Environment,
        SDK::Args::StateBag => Client::StateBag,
        SDK::Args::Target => Vagrant::Machine,
        SDK::Args::TargetIndex => Client::TargetIndex,
        SDK::Args::Target::Machine => Vagrant::Machine,
        SDK::Args::TerminalUI => Vagrant::UI::Remote,
        Client::Project => Vagrant::Environment,
        Client::Target => Vagrant::Machine,
        Client::Terminal => Vagrant::UI::Remote,
      }

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
        @known_arguments = args
        Mapper.generate_anys
        @mappers = Mapper.registered.map(&:new)
        @cacher = Util::Cacher.new
      end

      # Create a clone of this mappers instance
      #
      # @return [Mappers]
      def clone
        self.class.new(known_arguments).tap do |m|
          m.cacher = cacher
          m.mappers.replace(mappers.dup)
        end
      end

      # Add an argument to be included with mapping calls
      #
      # @param v [Object] Argument value
      # @return [Object]
      def add_argument(v)
        known_arguments << v
        v
      end

      # Convert Any proto message to actual message type
      #
      # @param any [Google::Protobuf::Any]
      # @return [Google::Protobuf::MessageExts]
      def unany(any)
        type = any.type_name.split('/').last.to_s.split('.').inject(Object) { |memo, name|
          c = memo.constants.detect { |mc| mc.to_s.downcase == name.to_s.downcase }
          raise NameError,
            "Failed to find constant for `#{any.type_name}'" if c.nil?
          memo.const_get(c)
        }
        any.unpack(type)
      end

      # Map a given value
      #
      # @param value [Object] Value to map
      # @param to [Class] Resultant type (optional)
      # @return [Object]
      def map(value, *extra_args, to: nil)
        # If we don't have a destination type provided, attempt
        # to set it using our default maps
        to = DEFAULT_MAPS[value.class] if to.nil?

        logger.debug("starting the value mapping process #{value} => #{to.nil? ? 'unknown' : to.inspect}")
        if value.nil? && to
          val = (extra_args + known_arguments).detect do |item|
            item.is_a?(to)
          end
          return val if val
        end

        # NOTE: We set the cacher instance into the extra args
        # instead of adding it as a known argument so if it is
        # changed the correct instance will be used
        extra_args << cacher
        extra_args << self

        if value.is_a?(Google::Protobuf::Any)
          non_any = unany(value)
          logger.debug("extracted any proto message #{value} -> #{non_any}")
          value = non_any
        end

        # If the provided value is a protobuf value, just return that value
        if value.is_a?(Google::Protobuf::Value)
          logger.debug("direct return of protobuf value contents - #{value.to_ruby}")
          return value.to_ruby
        end

        args = ([value] + extra_args + known_arguments).compact
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
            logger.debug("removing mapper - invalid funcspec match - #{m}")
            nil
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
              "No valid mappers found for input type `#{value.class}' (#{value})"
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
                input_values: args,
              )
              result = m_graph.execute
              break
            rescue => err
              logger.debug("typeless mapping failure (non-critical): #{err} (input - #{value} / output #{out})")
              last_error = err
            end
          end
          raise last_error if result.nil? && last_error
        else
          m_graph = Internal::Graph::Mappers.new(
            output_type: to,
            mappers: map_mapper,
            input_values: args,
          )
          result = m_graph.execute
        end
        logger.debug("map of #{value} to #{to.nil? ? 'unknown' : to.inspect} => #{result}")
        result
      end

      # Generate the given type based on given and/or
      # added arguments
      def generate(*args, type:)
        map(nil, *args, to: type)
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
        logger.debug("converted funcspec argument #{v} -> #{result}")
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
require Vagrant.source_root.join("plugins/commands/serve/mappers/environment.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/guest.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/known_types.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/machine.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/pathname.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/project.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/state_bag.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/synced_folder.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/target.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/target_index.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/terminal.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/ui.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/wrappers.rb").to_s
