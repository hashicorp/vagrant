# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require "digest/sha2"
require "google/protobuf/wrappers_pb"
require "google/protobuf/well_known_types"

module VagrantPlugins
  module CommandServe
    # Provides value mapping to ease interaction
    # with protobuf and clients
    class Mappers
      # The default maps define the default mapping of proto
      # messages to a proper Ruby type. This is used when
      # mapping a value and a destination type is not provided.
      DEFAULT_MAPS = {
        Client::Project => Vagrant::Environment,
        Client::Target => Vagrant::Machine,
        Client::Terminal => Vagrant::UI::Remote,
        Client::SyncedFolder => Vagrant::Plugin::Remote::SyncedFolder,
        Google::Protobuf::BoolValue => Type::Boolean,
        Google::Protobuf::BytesValue => String,
        Google::Protobuf::DoubleValue => Float,
        Google::Protobuf::FloatValue => Float,
        Google::Protobuf::Int32Value => Integer,
        Google::Protobuf::Int64Value => Integer,
        Google::Protobuf::UInt32Value => Integer,
        Google::Protobuf::UInt64Value => Integer,
        Google::Protobuf::StringValue => String,
        SDK::Args::Array => Array,
        SDK::Args::ConfigData => Vagrant::Plugin::V2::Config,
        SDK::Args::Class => Class,
        SDK::Args::CorePluginManager => Client::CorePluginManager,
        SDK::Args::Direct => Type::Direct,
        SDK::Args::Folders => Type::Folders,
        SDK::Args::Guest => Client::Guest,
        SDK::Args::Hash => Hash,
        SDK::Args::Host => Client::Host,
        SDK::Args::NamedCapability => Symbol,
        SDK::Args::Null => NilClass,
        SDK::Args::Options => Type::Options,
        SDK::Args::Path => Pathname,
        SDK::Args::ProcRef => Proc,
        SDK::Args::Project => Vagrant::Environment,
        SDK::Args::Provider => Client::Provider,
        SDK::Args::StateBag => Client::StateBag,
        SDK::Args::SyncedFolder => Vagrant::Plugin::Remote::SyncedFolder,
        SDK::Args::Target => Vagrant::Machine,
        SDK::Args::TargetIndex => Client::TargetIndex,
        SDK::Args::Target::Machine => Vagrant::Machine,
        SDK::Args::TimeDuration => Type::Duration,
        SDK::Args::TerminalUI => Vagrant::UI::Remote,
        SDK::Command::Arguments => Type::CommandArguments,
        SDK::Command::CommandInfo => Type::CommandInfo,
        SDK::Communicator::Command => Type::CommunicatorCommandArguments,
        SDK::Config::RawRubyValue => Object,
      }

      # The reverse maps define the default mapping from Ruby types
      # to proto messages. This map is built by reversing the default
      # maps. The key values are checked against the source value's
      # class and its ancestors for a match. This is why the UI interface
      # is merged into the map.
      REVERSE_MAPS = Hash[DEFAULT_MAPS.values.zip(DEFAULT_MAPS.keys)].merge(
        Vagrant::UI::Interface => SDK::Args::TerminalUI,
      )
      # Remove any top level classes
      REVERSE_MAPS.delete_if { |k, _| !k.name.include?("::") }
      # REVERSE_MAPS.delete(Object)

      # @return [Symbol] marker value for failed direct conversions
      FAILED_CONVERT = :__FAILED_CONVERT__

      # Constant used for generating value
      GENERATE_CLASS = Class.new {
        def self.to_s
          "[Value Generation]"
        end
        def to_s
          "[Value Generation]"
        end
        def inspect
          to_s
        end
      }
      GENERATE = GENERATE_CLASS.new.freeze

      include Util::HasLogger

      autoload :Internal, Vagrant.source_root.join("plugins/commands/serve/mappers/internal").to_s
      autoload :Mapper, Vagrant.source_root.join("plugins/commands/serve/mappers/mapper").to_s

      # @return [Array<Object>] arguments provided to all mapper calls
      attr_reader :known_arguments
      # @return [Array<Mapper>] list of mappers
      attr_reader :mappers
      # @return [Util::Cacher] cached mapped values
      attr_accessor :cacher

      class << self
        # @return [Array<Mapper>] frozen list of available mappers
        def mappers
          @mappers ||= Mapper.registered.map(&:new).freeze
        end

        # @return [Util::Cacher]
        def cache
          @cache ||= Util::Cacher.new
        end

        # Register a destination type for blind mappings
        #
        # @param src [Class] source type
        # @param dst [Class] destination type
        # @return [Class] destination type
        def register_blind_map(src, dst)
          @blind_map_registry[src] = dst
        end

        # Get a destination type for blind mapping if registered
        #
        # @param src [Class] source type
        # @return [Class, NilClass] destination type or nil
        def blind_map_for(src)
          @blind_map_registry[src]
        end
      end

      # Initialize our lookup table
      @blind_map_registry = {}

      # Create a new mappers instance. Any arguments provided will be
      # available to all mapper calls
      def initialize(*args)
        @known_arguments = Array(args).compact
        Mapper.generate_anys
        @mappers = self.class.mappers
        @cacher = self.class.cache
      end

      def initialize_copy(orig)
        @mappers = orig.mappers.dup
        @cacher = orig.cacher
        @known_arguments = orig.known_arguments
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
        parent_module_options = []
        name.to_s.split(".").inject(Object) { |memo, n|
          c = memo.constants.detect { |mc| mc.to_s.downcase == n.to_s.downcase }
          if c.nil?
            parent_module_options.delete(memo)
            parent_module_options.each do |pm|
              c = pm.constants.detect { |mc| mc.to_s.downcase == n.to_s.downcase }
              if !c.nil?
                memo = pm
                break
              end
            end
          end

          raise NameError,
            "Failed to find constant for `#{name}'" if c.nil?

          parent_module_options = memo.constants.select {
            |mc| mc.to_s.downcase == n.to_s.downcase
          }.map {
            |mc| memo.const_get(mc)
          }
          memo.const_get(c)
        }
      end

      # Attempt to directly convert value. If a destination type
      # is provided, validate the direct conversion matches the
      # desired type.
      #
      # @param value [Object] value to convert
      # @param to [Class] Resultant type (optional)
      # @return [Object]
      def direct_convert(value, to:)
        # If we don't have a destination, attempt to do direct conversion
        if to.nil?
          begin
            logger.trace { "running direct blind pre-map on #{value.class}" }
            return value.is_a?(Google::Protobuf::MessageExts) ? value.to_ruby : value.to_proto
          rescue => err
            logger.trace { "direct blind conversion failed in pre-map stage, reason: #{err}" }
          end
        end

        if !to.nil?
          # If we are mapping to an any, try doing it directly first
          if to == Google::Protobuf::Any
            begin
              return value.to_any
            rescue => err
              logger.trace { "direct any conversion failed in pre-map stage, reason: #{err}"}
            end
          end

          # If the destination type is a proto, try doing that directly
          if to.ancestors.include?(Google::Protobuf::MessageExts)
            begin
              proto = value.to_proto
              return proto if proto.is_a?(to)
            rescue => err
              logger.trace { "direct proto conversion failed in pre-map stage, reason: #{err}" }
            end
          end

          # If the destination type is not a proto, but the value is, try that directly
          if value.is_a?(Google::Protobuf::MessageExts) && !to.ancestors.include?(Google::Protobuf::MessageExts)
            begin
              val = value.to_ruby
              return val if val.is_a?(to)
            rescue => err
              logger.trace { "direct ruby conversion failed in pre-map stage, reason: #{err}" }
            end
          end
        end

        FAILED_CONVERT
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
            logger.debug { "extracted any proto message #{a.class} -> #{non_any.class}" }
            a = non_any
          end
          if name
            a = Type::NamedArgument.new(value: a, name: name)
          end
          a
        end
        value = extra_args.shift if value

        # If we don't have a destination type provided, attempt
        # to set it using our default maps
        to = DEFAULT_MAPS[value.class] if to.nil?
        if value != GENERATE && to.nil?
          to = REVERSE_MAPS.detect do |k, v|
            v if value.class.ancestors.include?(k) &&
              v.ancestors.include?(Google::Protobuf::MessageExts)
          end&.last
        end

        # If the value given is the desired type, just return the value
        return value if value != GENERATE && !to.nil? && to != Object && value.is_a?(to)

        # Let's try some shortcuts before we actually put in the work
        # of doing all the mapping stuff
        if value == GENERATE
          extra_args.each do |ea|
            val = direct_convert(ea, to: to)
            return val if val != FAILED_CONVERT
          end
        else
          val = direct_convert(value, to: to)
          return val if val != FAILED_CONVERT
        end

        # These only work if we know our destination

        logger.debug { "starting value mapping process #{value.class} -> #{to.nil? ? 'unknown' : to.inspect}" }
        if value.nil? && to
          val = (extra_args + known_arguments).detect do |item|
            item.is_a?(to)
          end
          if val && val != GENERATE
            return val
          end
        end

        # NOTE: We set the cacher instance into the extra args
        # instead of adding it as a known argument so if it is
        # changed the correct instance will be used
        extra_args << cacher
        extra_args << self

        # If the provided value is a protobuf value, just return that value
        if value.is_a?(Google::Protobuf::Value)
          logger.debug { "direct return of protobuf value contents - #{value.to_ruby}" }
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
            logger.trace { "removing mapper - invalid funcspec match - #{m}" }
            nil
          end.compact
          map_mapper.mappers.replace(valid_mappers)
        elsif value.is_a?(Google::Protobuf::MessageExts)
          map_mapper = self.clone
          valid_mappers = map_mapper.mappers.map do |m|
            next if value.class == m.output
            # next if value.is_a?(m.output)
            m
          end.compact
          map_mapper.mappers.replace(valid_mappers)
        else
          map_mapper = self
        end

        # If we don't have a desired final type, test for mappers
        # that are satisfied by the arguments we have and run that
        # directly
        if to.nil? && value != GENERATE && self.class.blind_map_for(value.class)
          blind_to = self.class.blind_map_for(value.class)
          logger.debug { "found existing blind mapping for type #{value.class} -> #{blind_to}" }
          to = blind_to
        end

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
            logger.debug { "attempting blind map #{value.class} -> #{out}" }
            begin
              m_graph = Internal::Graph::Mappers.new(
                output_type: out,
                mappers: map_mapper,
                named: named,
                input_values: args,
                source: value != GENERATE ? value.class : nil,
              )
              result = m_graph.execute
              to = out
              break
            rescue => err
              logger.debug { "typeless mapping failure (non-critical): #{err} (input - #{value.class} / output #{out})" }
              last_error = err
            end
          end
          raise last_error if result.nil? && last_error
          self.class.register_blind_map(value.class, to)
        else
          m_graph = Internal::Graph::Mappers.new(
            output_type: to,
            mappers: map_mapper,
            named: named,
            input_values: args,
            source: value != GENERATE ? value.class : nil
          )
          result = m_graph.execute
        end
        logger.debug { "map of #{value.class} to #{to.nil? ? 'unknown' : to.inspect} => #{result.class}" }
        if !result.is_a?(to)
          raise TypeError,
            "Value is not expected destination type `#{to}' (actual type: #{result.class})"
        end
        result
      rescue => err
        logger.debug { "mapping failed of #{value.class} to #{to.nil? ? 'unknown' : to.inspect} - #{err}" }
        logger.debug { "#{err.class}: #{err}\n" + err.backtrace.join("\n") }
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
            logger.debug { "mapping funcspec value #{arg.class} to expected type #{expect[i]}" }
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
            "FuncSpec value of type `#{v.class}' has no valid mappers (#{v})"
        end
        result = m.first.call(v)
        logger.trace { "converted funcspec argument #{v.class} -> #{result.class}" }
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
require Vagrant.source_root.join("plugins/commands/serve/mappers/config_data.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/core_plugin_manager.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/direct.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/duration.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/environment.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/folders.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/guest.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/host.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/known_types.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/machine.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/options.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/pathname.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/plugin_manager.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/proc.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/project.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/provider.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/provisioner.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/push.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/state_bag.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/synced_folder.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/target.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/target_index.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/terminal.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/ui.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/vagrantfile.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/wrappers.rb").to_s
