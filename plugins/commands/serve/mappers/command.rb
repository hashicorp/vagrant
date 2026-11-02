# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    class Mappers
      # Build a command arguments from a FuncSpec value
      class CommandArgumentsProtoFromSpec < Mapper
        def initialize
          inputs = [].tap do |i|
            i << Input.new(type: SDK::FuncSpec::Value) { |arg|
              arg.type == "hashicorp.vagrant.sdk.Command.Arguments" &&
                !arg&.value&.value.nil?
            }
          end
          super(inputs: inputs, output: SDK::Command::Arguments, func: method(:converter))
        end

        def converter(proto)
          SDK::Command::Arguments.decode(proto.value.value)
        end
      end

      class CommandArgumentsFromProto < Mapper
        def initialize
          super(
            inputs: [Input.new(type: SDK::Command::Arguments)],
            output: Type::CommandArguments,
            func: method(:converter)
          )
        end

        def converter(proto)
          args = proto.args.to_a
          flags = Hash.new.tap do |flgs|
            proto.flags.each do |f|
              if f.type == :BOOL
                flgs[f.name] = f.bool
              else
                flgs[f.name] = f.string
              end
            end
          end
          Type::CommandArguments.new(args: args, flags: flags)
        end
      end

      class CommandInfoFromProto < Mapper
        def initialize
          super(
            inputs: [Input.new(type: SDK::Command::CommandInfo)],
            output: Type::CommandInfo,
            func: method(:converter),
          )
        end

        def converter(proto)
          Type::CommandInfo.new(
            name: proto.name,
            help: proto.help,
            synopsis: proto.synopsis,
          ).tap do |c|
            proto.flags.each do |f|
              c.add_flag(
                long_name: f.long_name,
                short_name: f.short_name,
                description: f.description,
                default_value: f.default_value,
                type: f.type,
              )
            end
            proto.subcommands.each do |s_proto|
              c.add_subcommand(converter(s_proto))
            end
          end
        end
      end

      class CommandInfoToProto < Mapper
        def initialize
          super(
            inputs: [Input.new(type: Type::CommandInfo)],
            output: SDK::Command::CommandInfo,
            func: method(:converter),
          )
        end

        def converter(info)
          flags = info.flags.map do |f|
            SDK::Command::Flag.new(
              long_name: f.long_name,
              short_name: f.short_name,
              description: f.description,
              default_value: f.default_value,
              type: f.type == :BOOL ? SDK::Command::Flag::Type::BOOL :
                SDK::Command::Flag::Type::STRING
            )
          end
          subcommands = info.subcommands.map do |s_info|
            converter(s_info)
          end
          SDK::Command::CommandInfo.new(
            name: info.name,
            help: info.help,
            synopsis: info.synopsis,
            flags: flags,
            subcommands: subcommands,
            primary: info.primary,
          )
        end
      end

      class CommandProtoFromSpec < Mapper
        def initialize
          super(
            inputs: [Input.new(type: SDK::FuncSpec::Value) { |arg|
                arg.type == "hashicorp.vagrant.sdk.Args.Command" &&
                  !arg&.value&.value.nil?
              }
            ],
            output: SDK::Args::Command,
            func: method(:converter)
          )
        end

        def converter(fv)
          SDK::Args::Command.decode(fv.value.value)
        end
      end

      class CommandFromProto < Mapper
        def initialize
          inputs = [].tap do |i|
            i << Input.new(type: SDK::Args::Command)
            i << Input.new(type: Broker)
          end
          super(inputs: inputs, output: Client::Command, func: method(:converter))
        end

        def converter(proto, broker)
          Client::Command.load(proto, broker: broker)
        end
      end
    end
  end
end
