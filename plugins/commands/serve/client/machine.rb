module VagrantPlugins
  module CommandServe
    module Client
      class Machine

        attr_reader :client
        attr_reader :resource_id

        # Create a new instance
        def initialize(name:)
          @client = ServiceInfo.client_for(SDK::MachineService)
          if name.nil?
            @resource_id = ServiceInfo.info.machine
          else
            load_machine(name)
          end
        end

        # Seed this instance with the resource id for the
        # requested machine. If the machine doesn't already
        # exist, create it
        def load_machine(name)
          c = ServiceInfo.client_for(SRV::Vagrant)
          machine = SRV::Machine.new(
            name: name,
            project: SRV::Ref::Project.new(
              resource_id: ServiceInfo.info.project
            )
          )

          begin
            c.find_machine(SRV::FindMachineRequest.new(
              machine: machine))
            @resource_id = resp.machine.resource_id
            return
          rescue => err
            # validate this was really a 404
          end

          resp = c.upsert_machine(SRV::UpsertMachineRequest.new(
            machine: machine))
          @resource_id = resp.machine.resource_id
        end

        def ref
          SDK::Ref::Machine.new(resource_id: resource_id)
        end

        # @return [String] machine name
        def get_name
          req = SDK::Machine::GetNameRequest.new(
            machine: ref
          )
          client.get_name(req).name
        end

        def set_name(name)
          req = SDK::Machine::SetNameRequest.new(
            machine: ref,
            name: name
          )
          @client.set_name(req)
        end

        def get_id
          req = SDK::Machine::GetIDRequest.new(
            machine: ref
          )
          @client.get_id(req).id
        end

        def set_id(new_id)
          req = SDK::Machine::SetNameRequest.new(
            machine: ref,
            id: new_id
          )
          @client.set_id(req)
        end

        def get_box
          req = SDK::Machine::BoxRequest.new(
            machine: ref
          )
          resp = @client.box(req)
          Vagrant::Box.new(
            resp.box.name,
            resp.box.provider.to_sym,
            resp.box.version,
            Pathname.new(resp.box.directory),
          )
        end

        def get_data_dir
          req = SDK::Machine::DatadirRequest.new(
            machine: ref
          )
          @client.datadir(req).datadir
        end

        def get_local_data_path
          req = SDK::Machine::LocalDataPathRequest.new(
            machine: ref
          )
          @client.localdatapath(req).path
        end

        def get_provider
          req = SDK::Machine::ProviderRequest.new(
            machine: ref
          )
          @client.provider(req)
        end

        def get_vagrantfile_name
          req = SDK::Machine::VagrantfileNameRequest.new(
            machine: ref
          )
          resp = @client.vagrantfile_name(req)
          resp.name
        end

        def get_vagrantfile_path
          req = SDK::Machine::VagrantfilePathRequest.new(
            machine: ref
          )
          resp = @client.vagrantfile_path(req)
          Pathname.new(resp.path)
        end

        def updated_at
          req = SDK::Machine::UpdatedAtRequest.new(
            machine: ref
          )
          resp = @client.updated_at(req)
          resp.updated_at
        end

        # Get a machine by id
        #
        # @param [String] machine id
        # @param [TerminalClient]
        # @return [Machine]
        def get_machine(id, ui_client)
          provider_plugin  = Vagrant.plugin("2").manager.providers[:virtualbox]
          provider_cls     = provider_plugin[0]
          provider_options = provider_plugin[1]

          datadir = get_data_dir(id)
          vagrantfile_name = get_vagrantfile_name(id)
          vagrantfile_path = get_vagrantfile_path(id)
          env = Vagrant::Environment.new(
            cwd: vagrantfile_path, # TODO: this is probably not ideal
            home_path: datadir.root_dir,
            ui_class: Vagrant::UI::RemoteUI,
            ui_opts: [ui_client],
            vagrantfile_name: vagrantfile_name,
          )

          Machine.new(
            "virtualbox", provider_cls, {}, provider_options,
            nil, env, self, id
          )
        end
      end
    end

  end
end
