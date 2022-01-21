module VagrantPlugins
  module CommandServe
    module Util
      module FuncSpec
        # Generate FuncSpec proto args based on provided spec
        # using given args
        #
        # @param spec [SDK::FuncSpec] Spec for function
        # @param args [Array<Object>] List of arguments to generate from
        # @return [SDK::FuncSpec::Args]
        def generate_funcspec_args(spec, *args)
          if !spec.is_a?(SDK::FuncSpec)
            raise TypeError,
              "Expected `#{SDK::FuncSpec.name}' but received `#{spec.class.name}'"
          end
          m_args = args.dup
          if respond_to?(:seeds)
            m_args += seeds
          end

          SDK::FuncSpec::Args.new(
            args: spec.args.map { |farg|
              type = mapper.find_type(farg.type)
              any = Google::Protobuf::Any.pack(mapper.map(*m_args, named: farg.name, to: type))
              SDK::FuncSpec::Value.new(
                type: any.type_name.split("/").last,
                value: any,
                name: farg.name,
              )
            }
          )
        end

        # Convert all given args to FuncSpec::Args proto
        #
        # @param extra [Array<Object>] Extra arguments to use during mapping
        # @param args [Array<Object>] Arguments to be mapped
        # @return [SDK::FuncSpec::Args]
        def to_funcspec(*args, extra: [])
          SDK::FuncSpec::Args.new(
            args: args.map { |arg|
              if arg.is_a?(Type::NamedArgument)
                name = arg.name
                arg = arg.value
              else
                name = ""
              end
              any = mapper.map(arg, *extra, to: Google::Protobuf::Any)
              SDK::FuncSpec::Value.new(
                name: name,
                type: any.type_name.split("/").last,
                value: any,
              )
            }
          )
        end

        # Call a defined func and execute the callback.
        #
        # @param name [String,Symbol] Name of method which provides a spec and callback
        #                             (defaults to name of caller method with `_func` suffix)
        # @param args [Array<Object>] Optional list of arguments
        def run_func(*args, name: nil)
          if name.nil?
            name = caller_locations.first.label.to_s
            if name.end_with?("!") || name.end_with?("?")
              name = name[0, name.length - 1]
            end
            name += "_func"
          end
          if !respond_to?(name)
            raise ArgumentError,
              "Class `#{self.class}' does not contain method `##{name}'"
          end
          spec, cb = send(name)
          f_args = generate_funcspec_args(spec, *args)
          cb.call(f_args)
        end
      end
    end
  end
end
