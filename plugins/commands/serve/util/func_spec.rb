# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    module Util
      module FuncSpec
        module Client
          # Generate FuncSpec proto args based on provided spec
          # using given args
          #
          # @param spec [SDK::FuncSpec] Spec for function
          # @param args [Array<Object>] List of arguments to generate from
          # @return [SDK::FuncSpec::Args]
          def generate_funcspec_args(spec, *args)
            logger.trace("generating funcspec args for spec: #{spec}")
            if !spec.is_a?(SDK::FuncSpec)
              raise TypeError,
                "Expected `#{SDK::FuncSpec.name}' but received `#{spec.class.name}'"
            end
            m_args = args.dup
            if respond_to?(:seeds)
              m_args = m_args +
                seeds.typed.to_a +
                seeds.named.map { |name, val|
                  val = mapper.unany(val)
                  Type::NamedArgument.new(
                    name: name,
                    value: val,
                  )
                }
            end

            m_args += m_args.find_all { |arg|
              arg.is_a?(Type::Direct)
            }.map(&:value).flatten

            SDK::FuncSpec::Args.new(
              args: spec.args.map { |farg|
                logger.trace("starting funcspec generation for #{farg}")
                type = mapper.find_type(farg.type)
                gen = mapper.generate(*m_args, named: farg.name, type: type)
                logger.trace("generated value for type #{type.inspect} (name: #{farg.name.inspect}) -> #{gen.class}")
                any = Google::Protobuf::Any.pack(gen)
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
          def run_func(*args, name: nil, func_args: [])
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
            logger.trace("running func #{name} for spec and callback")
            func_args = [name] + Array(func_args)
            spec, cb = send(*func_args)
            f_args = generate_funcspec_args(spec, *args)
            logger.trace("executing func #{name.to_s.sub(/_func$/, "")}")
            cb.call(f_args)
          end
        end

        module Service
          def funcspec(args: [], named: {}, name: nil, result: nil)
            if name.nil?
              name = caller_locations[1].label.to_s
              if name.end_with?("!") || name.end_with?("?")
                name = name[0, name.length - 1]
              end
            end

            fargs = args.map { |a|
              a = make_proto(a)
              SDK::FuncSpec::Value.new(
                type: a.descriptor.name
              )
            } + named.map { |name, a|
              a = make_proto(a)
              SDK::FuncSpec::Value.new(
                name: name,
                type: a.descriptor.name
              )
            }

            result = Empty if result.nil?
            result = make_proto(result)

            SDK::FuncSpec.new(
              name: name.to_s.sub(/_spec$/, ""),
              args: fargs,
              result: [
                SDK::FuncSpec::Value.new(
                  type: result.descriptor.name,
                )
              ]
            )
          end

          def make_proto(v)
            return v if v.respond_to?(:descriptor)
            v = Mapper::REVERSE_MAP.detect do |k, v|
              v if value.class.ancestors.include?(k)
            end
            if v.nil?
              raise TypeError,
                "Type `#{v.class}' is not a proto message and a mapping cannot be found"
            end
            v
          end
        end
      end
    end
  end
end
