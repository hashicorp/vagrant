module VagrantPlugins
  module CommandServe
    class Mappers
      # Build a guest client from a proto instance
      class ProvisionerFromProto < Mapper
        def initialize
          inputs = [].tap do |i|
            i << Input.new(type: SDK::Args::Provisioner)
            i << Input.new(type: Broker)
          end
          super(inputs: inputs, output: Client::Provisioner, func: method(:converter))
        end

        def converter(proto, broker)
          Client::Provisioner.load(proto, broker: broker)
        end
      end

      class GeneralConfigFromSpec < Mapper
        def initialize
          inputs = [].tap do |i|
            i << Input.new(type: SDK::FuncSpec::Value) { |arg|
              arg.type == "hashicorp.vagrant.sdk.Vagrantfile.GeneralConfig" &&
                !arg&.value&.value.nil?
            }
          end
          super(inputs: inputs, output: SDK::Vagrantfile::GeneralConfig, func: method(:converter))
        end

        def converter(proto)
          proto.value.unpack(SDK::Vagrantfile::GeneralConfig)
        end
      end

      class ConfigToProto < Mapper
        def initialize
          inputs = [].tap do |i|
            i << Input.new(type: Vagrant::Plugin::V2::Config)
          end
          super(inputs: inputs, output: SDK::Vagrantfile::GeneralConfig, func: method(:converter))
        end

        def converter(config)
          config.to_proto(config.class.to_s)
        end
      end
    end
  end
end
