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
          logger.debug("Checking if ready")
          with_info(ctx) do |info|
            plugin_name = info.plugin_name
            logger.debug("Got plugin #{plugin_name}")
            target = mapper.funcspec_map(req)

            machine = mapper.map(target, to: Vagrant::Machine)
            logger.debug("Got machine #{machine}")

            plugin = Vagrant.plugin("2").manager.communicators[plugin_name.to_s.to_sym]
            logger.debug("Got plugin #{plugin}")

            ready = plugin.new(machine).ready?
            logger.debug("is ready: #{ready}")
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
          with_info(ctx) do |info|
            plugin_name = info.plugin_name
            logger.debug("Got plugin #{plugin_name}")
            target, wait_duration = mapper.funcspec_map(req)
            logger.debug("Got target #{target}")
            logger.debug("Got duration #{wait_duration}")

            machine = mapper.map(target, to: Vagrant::Machine)
            logger.debug("Got machine #{machine}")

            plugin = Vagrant.plugin("2").manager.communicators[plugin_name.to_s.to_sym]
            logger.debug("Got plugin #{plugin}")

            begin
              ready = plugin.new(machine).wait_for_ready(wait_duration)
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
                type: "hashicorp.vagrant.sdk.Args.Path",
                name: "",
              ),
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Args.Path",
                name: "",
              )
            ],
            result: [
              type: "hashicorp.vagrant.sdk.Communicator.FileTransferResp",
              name: "",
            ]
          )
        end

        def download(req, ctx)
          logger.debug("Uploading")
          with_info(ctx) do |info|
            plugin_name = info.plugin_name
            logger.debug("Got plugin #{plugin_name}")

            target, from, to = mapper.funcspec_map(req)
            logger.debug("Got target #{target}")
            logger.debug("Got from #{from}")
            logger.debug("Got to #{to}")

            logger.info("mapping received arguments to guest machine")
            machine = mapper.map(target, to: Vagrant::Machine)
            logger.debug("Got machine #{machine}")

            plugin = Vagrant.plugin("2").manager.communicators[plugin_name.to_s.to_sym]
            logger.debug("Got plugin #{plugin}")

            communicator = plugin.new(machine)
            logger.debug("communicator: #{communicator}")

            communicator.download(from, to)

            SDK::Communicator::FileTransferResp.new()
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
                type: "hashicorp.vagrant.sdk.Args.Path",
                name: "",
              ),
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Args.Path",
                name: "",
              )
            ],
            result: [
              type: "hashicorp.vagrant.sdk.Communicator.FileTransferResp",
              name: "",
            ]
          )
        end

        def upload(req, ctx)
          logger.debug("Uploading")
          with_info(ctx) do |info|
            plugin_name = info.plugin_name
            logger.debug("Got plugin #{plugin_name}")

            target, from, to = mapper.funcspec_map(req)
            logger.debug("Got target #{target}")
            logger.debug("Got from #{from}")
            logger.debug("Got to #{to}")

            logger.info("mapping received arguments to guest machine")
            machine = mapper.map(target, to: Vagrant::Machine)
            logger.debug("Got machine #{machine}")

            plugin = Vagrant.plugin("2").manager.communicators[plugin_name.to_s.to_sym]
            logger.debug("Got plugin #{plugin}")

            communicator = plugin.new(machine)
            logger.debug("communicator: #{communicator}")

            communicator.upload(from, to)

            SDK::Communicator::FileTransferResp.new()
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
                type: "hashicorp.vagrant.sdk.Args.Command",
                name: "",
              ),
              SDK::FuncSpec::Value.new(
                type: "", # TODO: get opts
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
          with_info(ctx) do |info|
            plugin_name = info.plugin_name
            logger.debug("Got plugin #{plugin_name}")

            target, cmd, opts = mapper.funcspec_map(req)
            logger.debug("Got machine #{target}")
            logger.debug("Got opts #{opts}")
            logger.debug("Got cmd #{cmd}")

            logger.info("mapping received arguments to guest machine")
            machine = mapper.map(target, to: Vagrant::Machine)
            logger.debug("Got machine #{machine}")

            plugin = Vagrant.plugin("2").manager.communicators[plugin_name.to_s.to_sym]
            logger.debug("Got plugin #{plugin}")

            communicator = plugin.new(machine)
            logger.debug("communicator: #{communicator}")

            exit_code = communicator.execute(cmd, opts)
            logger.debug("command exit code: #{exit_code}")

            SDK::Communicator::ExecuteResp.new(
              exit_code: exit_code
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
                type: "hashicorp.vagrant.sdk.Args.Command",
                name: "",
              ),
              SDK::FuncSpec::Value.new(
                type: "", # TODO: get opts
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
          with_info(ctx) do |info|
            plugin_name = info.plugin_name
            logger.debug("Got plugin #{plugin_name}")

            target, cmd, opts = mapper.funcspec_map(req)
            logger.debug("Got machine #{target}")
            logger.debug("Got opts #{opts}")
            logger.debug("Got cmd #{cmd}")

            logger.info("mapping received arguments to guest machine")
            machine = mapper.map(target, to: Vagrant::Machine)
            logger.debug("Got machine #{machine}")

            plugin = Vagrant.plugin("2").manager.communicators[plugin_name.to_s.to_sym]
            logger.debug("Got plugin #{plugin}")

            communicator = plugin.new(machine)
            logger.debug("communicator: #{communicator}")

            exit_code = communicator.sudo(cmd, opts)
            logger.debug("command exit code: #{exit_code}")

            SDK::Communicator::ExecuteResp.new(
              exit_code: exit_code
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
                type: "hashicorp.vagrant.sdk.Args.Command",
                name: "",
              ),
              SDK::FuncSpec::Value.new(
                type: "", # TODO: get opts
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
          with_info(ctx) do |info|
            plugin_name = info.plugin_name
            logger.debug("Got plugin #{plugin_name}")

            target, cmd, opts = mapper.funcspec_map(req)
            logger.debug("Got machine #{target}")
            logger.debug("Got opts #{opts}")
            logger.debug("Got cmd #{cmd}")

            logger.info("mapping received arguments to guest machine")
            machine = mapper.map(target, to: Vagrant::Machine)
            logger.debug("Got machine #{machine}")

            plugin = Vagrant.plugin("2").manager.communicators[plugin_name.to_s.to_sym]
            logger.debug("Got plugin #{plugin}")

            communicator = plugin.new(machine)
            logger.debug("communicator: #{communicator}")

            valid = communicator.test(cmd, opts)
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
          with_info(ctx) do |info|
            plugin_name = info.plugin_name
            logger.debug("Got plugin #{plugin_name}")
            target = mapper.funcspec_map(req)

            machine = mapper.map(target, to: Vagrant::Machine)
            logger.debug("Got machine #{machine}")

            plugin = Vagrant.plugin("2").manager.communicators[plugin_name.to_s.to_sym]
            logger.debug("Got plugin #{plugin}")

            communicator = plugin.new(machine)
            logger.debug("communicator: #{communicator}")

            communicator.reset()

            SDK::Communicator::ResetResp.new()
          end
        end
      end
    end
  end
end
