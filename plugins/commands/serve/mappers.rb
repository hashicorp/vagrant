require "digest/sha2"

module VagrantPlugins
  module CommandServe
    # Provides value mapping to ease interaction
    # with protobuf and clients
    class Mappers
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
        @mappers = Mapper.registered.map(&:new)
        @identifiers = []
      end

      # Add an argument to be included with mapping calls
      #
      # @param v [Object] Argument value
      # @return [Object]
      def add_argument(v)
        known_arguments << v
        @identifiers << identify(v)
        v
      end

      def cached(key)
        return false if cacher.nil?
        cacher[key]
      end

      def cache_key(*args)
        key = Digest::SHA256.new
        @identifiers.each { |i| key << i }
        args.each do |a|
          key << identify(a)
        end
        key.hexdigest
      end

      def identify(thing)
        thing.respond_to?(:cacher_id) ?
          thing.cacher_id.to_s :
          thing.object_id.to_s
      end

      # Map a given value
      #
      # @param value [Object] Value to map
      # @param to [Class] Resultant type (optional)
      # @return [Object]
      def map(value, *extra_args, to: nil)
        # If we already processed this value, return cached value
        cache_key = cache_key(value, *extra_args, to)
        if c = cached(cache_key)
          return c
        end

        if value.nil? && to
          val = (extra_args + known_arguments).detect do |item|
            item.is_a?(to)
          end
          return val if val
        end

        # If we don't have a desired final type, test for mappers
        # that are satisfied by the arguments we have and run that
        # directly
        if to.nil?
          args = ([value] + extra_args + known_arguments).compact
          matched_mappers = mappers.find_all do |m|
            if m.satisfied_by?(*args)
              if to
                m.output.ancestors.include?(to)
              else
                true
              end
            else
              false
            end
          end
          if matched_mappers.empty?
            raise ArgumentError,
              "Failed to locate valid mapper. (source: #{value ? value.class : 'none'} " \
              "destination: #{to ? to : 'undefined'} - args: #{args.map(&:class).inspect} )" \
          end
          if matched_mappers.size > 1
            m = matched_mappers.detect do |mp|
              mp.inputs.detect do |mi|
                mi.valid?(args.first)
              end
            end
            if m.nil?
              raise ArgumentError,
                "Multiple valid mappers found: #{matched_mappers.map(&:class).inspect} (source: #{value ? value.class : 'none'} " \
                "destination: #{to ? to : 'undefined'} - args: #{args.map(&:class).inspect} )"
            end
            matched_mappers = [m]
          end
          mapper = matched_mappers.first
          margs = mapper.determine_inputs(*args)
          result = mapper.call(*margs)
        else
          args = ([value] + extra_args).compact
          m_graph = Internal::Graph::Mappers.new(
            output_type: to,
            mappers: self,
            input_values: args,
          )
          result = m_graph.execute
        end
        cacher[cache_key] = result if cacher
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
      # @return [Array<Object>, Object]
      def funcspec_map(spec)
        result = spec.args.map do |arg|
          map(arg)
        end
        if result.size == 1
          return result.first
        end
        # NOTE: the spec will have the order of the arguments
        # shifted one. not sure why, but we can just work around
        # it here for now.
        result.push(result.shift)
      end
    end
  end
end

require Vagrant.source_root.join("plugins/commands/serve/mappers/guest.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/machine.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/project.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/target.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/target_index.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/terminal.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/command.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/capability.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/state_bag.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/ui.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/environment.rb").to_s
