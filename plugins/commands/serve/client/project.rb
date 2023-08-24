# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

module VagrantPlugins
  module CommandServe
    class Client
      class Project < Client

        # returns [List<VagrantPlugins::CommandServe::Client::Target>]
        def active_targets
          t = client.active_targets(Empty.new)
          targets = []
          t.targets.each do |target|
            targets << Target.load(target, broker: broker)
          end
          targets
        end

        # return [VagrantPlugins::CommandServe::Client::BoxCollection]
        def boxes
          BoxCollection.load(
            client.boxes(Empty.new),
            broker: broker
          )
        end

        # return [String]
        def cache_dir
          data_dirs.cache_dir
        end

        # return [String]
        def config_dir
          data_dirs.config_dir
        end

        # return [String]
        def cwd
          resp = client.cwd(Empty.new)
          resp.path
        end

        # return [Sdk::Args::DataDir::Project]
        def data_dirs
          resp = client.data_dir(Empty.new)
          resp
        end

        # return [String]
        def data_dir
          data_dirs.data_dir
        end

        # return [String]
        def default_private_key
          resp = client.default_private_key(Empty.new)
          resp.path
        end

        def default_provider(opts={})
          req = ::Hashicorp::Vagrant::Sdk::Project::DefaultProviderRequest.new(
            exclude: opts.fetch(:exclude, []),
            force_default: opts.fetch(:force_default, true),
            check_usable: opts.fetch(:check_usable, true),
            machine_name: opts[:machine],
          )
          resp = client.default_provider(req)
          resp.provider_name.to_sym
        end

        # return [String]
        def home
          resp = client.home(Empty.new)
          resp.path
        end

        # returns [VagrantPlugins::CommandServe::Client::Host]
        def host
          h = client.host(Empty.new)
          Host.load(h, broker: broker)
        end

        # return [String]
        def local_data
          resp = client.local_data(Empty.new)
          resp.path
        end

        # return [Vagrant::Machine]
        def machine(name, provider)
          logger.info("getting machine from vagrant-go name: #{name} provider: #{provider}")
          t = target(name, provider)
          Vagrant::Machine.new(client: t)
        end

        # return [String]
        def primary_target_name
          resp = client.primary_target_name(Empty.new)
          resp.name
        end

        # @return [String] resource identifier for this target
        def resource_id
          client.resource_id(Empty.new).resource_id
        end

        # return [String]
        def root_path
          resp = client.root_parh(Empty.new)
          resp.path
        end

        # return [<String>]
        def target_names
          resp = client.target_names(Empty.new)
          resp.names
        end

        # return [VagrantPlugins::CommandServe::Client::TargetIndex]
        def target_index
          TargetIndex.load(
            client.target_index(Empty.new),
            broker: broker
          )
        end

        # return [<String>]
        def target_ids
          resp = client.target_ids(Empty.new)
          resp.ids
        end

        # Returns a machine client for the given name
        # return [VagrantPlugins::CommandServe::Client::Target::Machine]
        def target(name, provider)
          target = Target.load(
            client.target(
              SDK::Project::TargetRequest.new(
                name: name,
                provider: provider,
              )
            ),
            broker: broker
          )
          target.to_machine
        end

        # return [String]
        def temp_dir
          data_dirs.temp_dir
        end

        # return [String]
        def tmp
          resp = client.tmp(Empty.new)
          resp.path
        end

        def vagrantfile
          client.vagrantfile(Empty.new).to_ruby
        end

        # @return [String] name of the Vagrantfile for this target
        def vagrantfile_name
          client.vagrantfile_name(Empty.new).name
        end

        # @return [Pathname] path to the Vagrnatfile for this target
        def vagrantfile_path
          Pathname.new(client.vagrantfile_path(Empty.new).path)
        end

        # @return [Terminal]
        def ui
          begin
            Terminal.load(
              client.ui(Google::Protobuf::Empty.new),
              broker: @broker,
            )
          rescue => err
            raise "Failed to load terminal via project: #{err}"
          end
        end
      end
    end
  end
end
