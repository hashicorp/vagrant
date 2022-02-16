require "google/protobuf/well_known_types"

module VagrantPlugins
  module CommandServe
    module Service
      class CommunicatorService < ProtoService(SDK::CommunicatorService::Service)
        def ready_spec(*_)
          logger.debug("generating ready spec")
          funcspec(
            args: [
              SDK::Target::Machine,
            ],
            result: SDK::Communicator::ReadyResp,
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
          funcspec(
            args: [
              SDK::Args::Target::Machine,
              SDK::Args::TimeDuration,
            ],
            result: SDK::Communicator::ReadyResp,
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
          funcspec(
            args: [
              SDK::Args::Target::Machine,
            ],
            named: {
              source: SDK::Args::Path,
              destination: SDK::Args::Path,
            },
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
          funcspec(
            args: [
              SDK::Args::Target::Machine,
            ],
            named: {
              source: SDK::Args::Path,
              destination: SDK::Args::Path,
            }
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
          funcspec(
            args: [
              SDK::Args::Target::Machine,
              SDK::Communicator::Command,
              SDK::Args::Options,
            ],
            result: SDK::Communicator::ExecuteResp,
          )
        end

        def execute(req, ctx)
          with_info(ctx, broker: broker) do |info|
            plugin_name = info.plugin_name
            logger.debug("got req: #{req}")
            machine, cmd, opts = mapper.funcspec_map(
              req, mapper, broker,
              expect: [Vagrant::Machine, SDK::Communicator::Command, Type::Options]
            )

            plugin = Vagrant.plugin("2").manager.communicators[plugin_name.to_s.to_sym]
            communicator = plugin.new(machine)
            output = {stdout: '', stderr: ''}
            exit_code = communicator.execute(cmd.command, opts.value) {
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
          funcspec(
            args: [
              SDK::Args::Target::Machine,
              SDK::Communicator::Command,
              SDK::Args::Options,
            ],
            result: SDK::Communicator::ExecuteResp,
          )
        end

        def privileged_execute(req, ctx)
          with_info(ctx, broker: broker) do |info|
            plugin_name = info.plugin_name
            machine, cmd, opts = mapper.funcspec_map(
              req, mapper, broker,
              expect: [Vagrant::Machine, SDK::Communicator::Command, Type::Options]
            )

            plugin = Vagrant.plugin("2").manager.communicators[plugin_name.to_s.to_sym]
            communicator = plugin.new(machine)
            output = {stdout: '', stderr: ''}
            exit_code = communicator.sudo(cmd.command, opts.value) {
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
          funcspec(
            args: [
              SDK::Args::Target::Machine,
              SDK::Communicator::Command,
              SDK::Args::Options,
            ],
            result: SDK::Communicator::TestResp,
          )
        end

        def test(req, ctx)
          with_info(ctx, broker: broker) do |info|
            plugin_name = info.plugin_name
            machine, cmd, opts = mapper.funcspec_map(
              req, mapper, broker,
              expect: [Vagrant::Machine, SDK::Communicator::Command, Type::Options]
            )

            plugin = Vagrant.plugin("2").manager.communicators[plugin_name.to_s.to_sym]
            communicator = plugin.new(machine)
            valid = communicator.test(cmd.command, opts.value)
            logger.debug("command is valid?: #{valid}")

            SDK::Communicator::TestResp.new(
              valid: valid
            )
          end
        end

        def reset_spec(*_)
          funcspec(
            args: [
              SDK::Args::Target::Machine,
            ],
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
