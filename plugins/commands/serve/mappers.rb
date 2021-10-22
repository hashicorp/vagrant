require "digest/sha2"

module VagrantPlugins
  module CommandServe
    # Provides value mapping to ease interaction
    # with protobuf and clients
    class Mappers
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

        args = ([value] + extra_args + known_arguments).compact
        result = nil

        # If we don't have a desired final type, test for mappers
        # that are satisfied by the arguments we have and run that
        # directly
        if to.nil?
          valid_outputs = []
          cb = lambda do |k|
            matches = mappers.find_all do |m|
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
          logger.debug("mapper output types discovered for input type `#{value.class}': #{valid_outputs}")
          last_error = nil
          valid_outputs.each do |out|
            begin
              m_graph = Internal::Graph::Mappers.new(
                output_type: out,
                mappers: self,
                input_values: args,
              )
              result = m_graph.execute
            rescue => err
              logger.debug("typeless mapping failure (non-critical): #{err} (input - #{value} / output #{out})")
              last_error = err
            end
          end
          raise last_error if result.nil? && last_error
        else
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
      def funcspec_map(spec, *extra_args)
        result = spec.args.map do |arg|
          map(arg, *extra_args)
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

# NOTE: Always directly load mappers so they are automatically registered and
#       available. Using autoloading behavior will result in them being unaavailable
#       until explicitly requested by name
require Vagrant.source_root.join("plugins/commands/serve/mappers/capabilities.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/command.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/direct.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/environment.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/guest.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/known_types.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/machine.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/project.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/state_bag.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/target.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/target_index.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/terminal.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/ui.rb").to_s
require Vagrant.source_root.join("plugins/commands/serve/mappers/wrappers.rb").to_s
