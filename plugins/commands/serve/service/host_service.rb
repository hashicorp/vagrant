require "google/protobuf/well_known_types"

module VagrantPlugins
  module CommandServe
    module Service
      class HostService < Hashicorp::Vagrant::Sdk::HostService::Service
        prepend Util::HasBroker
        prepend Util::ExceptionLogger

        def detect_spec(*_)
          SDK::FuncSpec.new(
            name: "detect_spec",
            result: [
              type: "hashicorp.vagrant.sdk.Host.DetectResp",
              name: "",
            ]
          )
        end

        def detect(req, ctx)
          ServiceInfo.with_info(ctx) do |info|
            plugin_name = info.plugin_name
            plugin = Vagrant.plugin("2").manager.hosts[plugin_name.to_s.to_sym].to_a.first
            if !plugin
              raise "Failed to locate host plugin for: #{plugin_name.inspect}"
            end
            host = plugin.new
            SDK::Host::DetectResp.new(
              detected: host.detect?({}), # TODO(spox): argument should be env/state bag
            )
          end
        end

        def parents_spec(*_)
          SDK::FuncSpec.new(
            name: "parents_spec",
            result: [
              type: "hashicorp.vagrant.sdk.Host.ParentsResp",
              name: "",
            ]
          )
        end

        def parents(req, ctx)
          ServiceInfo.with_info(ctx) do |info|
            plugin_name = info.plugin_name
            plugin = Vagrant.plugin("2").manager.hosts[plugin_name.to_s.to_sym].to_a.first
            if !plugin
              raise "Failed to locate host plugin for: #{plugin_name.inspect}"
            end
            SDK::Host::ParentsResp.new(
              parents: plugin.new.parents
            )
          end
        end

        def has_capability_spec(*_)
          SDK::FuncSpec.new(
            name: "has_capability_spec",
            args: [
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Args.NamedCapability",
                name: "",
              )
            ],
            result: [
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Host.Capability.CheckResp",
                name: "",
              ),
            ],
          )
        end

        def has_capability(req, ctx)
          ServiceInfo.with_info(ctx) do |info|
            plugin_name = info.plugin_name
            n_cap = req.args.detect { |a|
              a.type == 'hashicorp.vagrant.sdk.Args.NamedCapability'
            }&.value&.value
            p = Vagrant::Host.new(
              plugin_name.to_sym,
              Vagrant.plugin("2").manager.hosts,
              Vagrant.plugin("2").manager.host_capabilities,
              nil,
            )
            SDK::Host::Capability::CheckResp.new(
              has_capability: p.capability?(n_cap.strip.to_s.to_sym)
            )
          end
        end

        def capability_spec(*_)
          SDK::FuncSpec.new(
            name: "capability_spec",
            args: [
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Args.TerminalUI",
                name: "",
              ),
            ],
            result: [
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Host.Capability.Resp"
              )
            ]
          )
        end

        def capability(req, ctx)
          ServiceInfo.with_info(ctx) do |info|
            begin

              res = nil
              plugin_name = info.plugin_name
              n_cap = req.name
              raw_terminal = req.func_args.args.detect { |a|
                a.type == "hashicorp.vagrant.sdk.Args.TerminalUI"
              }&.value&.value
              ui_client = Client::Terminal.load(raw_terminal, broker: broker)
              ui = Vagrant::UI::RemoteUI.new(ui_client)

              p = Vagrant::Host.new(
                plugin_name.to_sym,
                Vagrant.plugin("2").manager.hosts,
                Vagrant.plugin("2").manager.host_capabilities,
                nil,
              )
              res = p.capability(n_cap.to_s.strip.to_sym, ui) # TODO(spox): first arg needs to be env / statebag
              vres = Google::Protobuf::Value.new
              vres.from_ruby(res)

              SDK::Host::Capability::Resp.new(
                result: Google::Protobuf::Any.pack(vres)
              )
            rescue => err
              raise "#{err.class}: #{err}\n#{err.backtrace.join("\n")}"
            end
          end
        end
      end
    end
  end
end
