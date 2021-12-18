require "google/protobuf/well_known_types"

module VagrantPlugins
  module CommandServe
    module Service
      class CommunicatorService < Hashicorp::Vagrant::Sdk::CommunicatorService::Service
        include Util::ServiceInfo

        prepend Util::HasMapper
        prepend Util::HasBroker
        prepend Util::ExceptionLogger
        prepend Util::HasLogger
        include Util::HasSeeds::Service

        def initialize(*args, **opts, &block)
          super()
        end

        def ready_spec(*_)
          logger.debug("generating ready spec")
          SDK::FuncSpec.new(
            name: "ready_spec",
            args: [
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Args.Target.Machine",
                name: "",
              )
            ],
            result: [
              type: "hashicorp.vagrant.sdk.Communicator.ReadyResp",
              name: "",
            ]
          )
        end

        def ready(req, ctx)
          with_info(ctx, broker: broker) do |info|
            plugin_name = info.plugin_name
            machine = mapper.funcspec_map(
              req, mapper, broker,
              expect: [Vagrant::Machine]
            )
            plugin = Vagrant.plugin("2").manager.communicators[plugin_name.to_s.to_sym]
            communicator = plugin.new(machine)
            ready = communicator.ready?
            SDK::Communicator::ReadyResp.new(
              ready: ready
            )
          end
        end

        def wait_for_ready_spec(*_)
          SDK::FuncSpec.new(
            name: "ready_spec",
            args: [
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Args.Target.Machine",
                name: "",
              ),
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Args.TimeDuration",
                name: "",
              )
            ],
            result: [
              type: "hashicorp.vagrant.sdk.Communicator.ReadyResp",
              name: "",
            ]
          )
        end

        def wait_for_ready(req, ctx)
          with_info(ctx, broker: broker) do |info|
            plugin_name = info.plugin_name
            machine, wait_duration = mapper.funcspec_map(
              req, mapper, broker,
              expect: [Vagrant::Machine, SDK::Args::TimeDuration]
            )
            plugin = Vagrant.plugin("2").manager.communicators[plugin_name.to_s.to_sym]

            begin
              ready = plugin.new(machine).wait_for_ready(wait_duration.duration)
            rescue => err
              logger.error(err)
              logger.debug("#{err.class}: #{err}\n#{err.backtrace.join("\n")}")
              raise
            end
            logger.debug("ready? #{ready}")
            SDK::Communicator::ReadyResp.new(
              ready: ready
            )
          end
        end

        def download_spec(*_)
          SDK::FuncSpec.new(
            name: "download_spec",
            args: [
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Args.Target.Machine",
                name: "",
              ),
              SDK::FuncSpec::Value.new(
                name: "source"
              ),
              SDK::FuncSpec::Value.new(
                name: "destination"
              ),
            ],
            result: []
          )
        end

        def download(req, ctx)
          logger.debug("Downloading")
          with_info(ctx, broker: broker) do |info|
            plugin_name = info.plugin_name
            dest_proto = req.args.select{ |a| a.name == "destination" }.first
            to = mapper.map(dest_proto.value, to: Pathname).to_s
            source_proto = req.args.select{ |a| a.name == "source" }.first
            from = mapper.map(source_proto.value, to: Pathname).to_s
            req.args.reject!{ |a| a.name == "source" || a.name == "destination" }
            machine  = mapper.funcspec_map(
              req, mapper, broker,
              expect: [Vagrant::Machine]
            )

            plugin = Vagrant.plugin("2").manager.communicators[plugin_name.to_s.to_sym]
            communicator = plugin.new(machine)
            communicator.download(from, to)
            Empty.new
          end
        end

        def upload_spec(*_)
          SDK::FuncSpec.new(
            name: "upload_spec",
            args: [
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Args.Target.Machine",
                name: "",
              ),
              SDK::FuncSpec::Value.new(
                name: "source"
              ),
              SDK::FuncSpec::Value.new(
                name: "destination"
              ),
            ],
            result: []
          )
        end

        def upload(req, ctx)
          logger.debug("Uploading")
          with_info(ctx, broker: broker) do |info|
            plugin_name = info.plugin_name
            dest_proto = req.args.select{ |a| a.name == "destination" }.first
            to = mapper.map(dest_proto.value, to: Pathname).to_s
            source_proto = req.args.select{ |a| a.name == "source" }.first
            from = mapper.map(source_proto.value, to: Pathname).to_s
            req.args.reject!{ |a| a.name == "source" || a.name == "destination" }
            machine  = mapper.funcspec_map(
              req, mapper, broker,
              expect: [Vagrant::Machine]
            )

            plugin = Vagrant.plugin("2").manager.communicators[plugin_name.to_s.to_sym]
            communicator = plugin.new(machine)
            communicator.upload(from, to)
            Empty.new
          end
        end

        def execute_spec(*_)
          SDK::FuncSpec.new(
            name: "execute_spec",
            args: [
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Args.Target.Machine",
                name: "",
              ),
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Communicator.Command",
                name: "",
              ),
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Args.Hash",
                name: "",
              )
            ],
            result: [
              type: "hashicorp.vagrant.sdk.Communicator.ExecuteResp",
              name: "",
            ]
          )
        end

        def execute(req, ctx)
          with_info(ctx, broker: broker) do |info|
            plugin_name = info.plugin_name
            logger.debug("got req: #{req}")
            machine, cmd, opts = mapper.funcspec_map(
              req, mapper, broker,
              expect: [Vagrant::Machine, SDK::Communicator::Command, Hash]
            )

            plugin = Vagrant.plugin("2").manager.communicators[plugin_name.to_s.to_sym]
            communicator = plugin.new(machine)
            opts.transform_keys!(&:to_sym)
            output = {stdout: '', stderr: ''}
            exit_code = communicator.execute(cmd.command, opts) {
              |type, data| output[type] << data if output[type]
            }

            SDK::Communicator::ExecuteResp.new(
              exit_code: exit_code,
              stdout: output[:stdout],
              stderr: output[:stderr]
            )
          end
        end

        def privileged_execute_spec(*_)
          SDK::FuncSpec.new(
            name: "privileged_execute_spec",
            args: [
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Args.Target.Machine",
                name: "",
              ),
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Communicator.Command",
                name: "",
              ),
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Args.Hash",
                name: "",
              )
            ],
            result: [
              type: "hashicorp.vagrant.sdk.Communicator.ExecuteResp",
              name: "",
            ]
          )
        end

        def privileged_execute(req, ctx)
          with_info(ctx, broker: broker) do |info|
            plugin_name = info.plugin_name
            machine, cmd, opts = mapper.funcspec_map(
              req, mapper, broker,
              expect: [Vagrant::Machine, SDK::Communicator::Command, Hash]
            )

            plugin = Vagrant.plugin("2").manager.communicators[plugin_name.to_s.to_sym]
            communicator = plugin.new(machine)
            opts.transform_keys!(&:to_sym)
            output = {stdout: '', stderr: ''}
            exit_code = communicator.sudo(cmd.command, opts) {
              |type, data| output[type] << data if output[type]
            }

            SDK::Communicator::ExecuteResp.new(
              exit_code: exit_code,
              stdout: output[:stdout],
              stderr: output[:stderr]
            )
          end
        end

        def test_spec(*_)
          SDK::FuncSpec.new(
            name: "test_spec",
            args: [
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Args.Target.Machine",
                name: "",
              ),
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Communicator.Command",
                name: "",
              ),
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Args.Hash",
                name: "",
              )
            ],
            result: [
              type: "hashicorp.vagrant.sdk.Communicator.TestResp",
              name: "",
            ]
          )
        end

        def test(req, ctx)
          with_info(ctx, broker: broker) do |info|
            plugin_name = info.plugin_name
            machine, cmd, opts = mapper.funcspec_map(
              req, mapper, broker,
              expect: [Vagrant::Machine, SDK::Communicator::Command, Hash]
            )

            plugin = Vagrant.plugin("2").manager.communicators[plugin_name.to_s.to_sym]
            communicator = plugin.new(machine)
            opts.transform_keys!(&:to_sym)
            valid = communicator.test(cmd.command, opts)
            logger.debug("command is valid?: #{valid}")

            SDK::Communicator::TestResp.new(
              valid: valid
            )
          end
        end

        def reset_spec(*_)
          SDK::FuncSpec.new(
            name: "reset_spec",
            args: [
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Args.Target.Machine",
                name: "",
              ),
            ],
            result: [
              type: "hashicorp.vagrant.sdk.Communicator.ResetResp",
              name: "",
            ]
          )
        end

        def reset(req, ctx)
          with_info(ctx, broker: broker) do |info|
            plugin_name = info.plugin_name
            machine = mapper.funcspec_map(
              req, mapper, broker,
              expect: [Vagrant::Machine]
            )

            plugin = Vagrant.plugin("2").manager.communicators[plugin_name.to_s.to_sym]
            communicator = plugin.new(machine)
            communicator.reset
            Empty.new
          end
        end
      end
    end
  end
end
