require "vagrant/plugin/v2/plugin"
require "vagrant/vagrantfile"
require "vagrant/box_collection"
require "vagrant/config"
require "pathname"

require 'google/protobuf/well_known_types'

module VagrantPlugins
  module CommandServe
    module Service
      class InternalService < Hashicorp::Vagrant::RubyVagrant::Service
        prepend Util::HasBroker
        prepend Util::ExceptionLogger

        LOG = Log4r::Logger.new("vagrant::command::serve::service::internal")

        PROVIDER_PROTO_CLS = Hashicorp::Vagrant::Sdk::Vagrantfile::Provider
        PROVISION_PROTO_CLS = Hashicorp::Vagrant::Sdk::Vagrantfile::Provisioner
        SYNCED_FOLDER_PROTO_CLS = Hashicorp::Vagrant::Sdk::Vagrantfile::SyncedFolder
        NETWORK_PROTO_CLS = Hashicorp::Vagrant::Sdk::Vagrantfile::Network
        GENERAL_CONFIG_CLS = Hashicorp::Vagrant::Sdk::Vagrantfile::GeneralConfig

        CONFIG_VM_CLS =  Hashicorp::Vagrant::Sdk::Vagrantfile::ConfigVM
        CONFIG_SSH_CLS = Hashicorp::Vagrant::Sdk::Vagrantfile::ConfigSSH
        CONFIG_WINRM_CLS = Hashicorp::Vagrant::Sdk::Vagrantfile::ConfigWinRM
        CONFIG_WINSSH_CLS = Hashicorp::Vagrant::Sdk::Vagrantfile::ConfigWinssh
        CONFIG_VAGRANT_CLS = Hashicorp::Vagrant::Sdk::Vagrantfile::ConfigVagrant

        def get_plugins(req, _unused_call)
          plugins = []
          plugin_manager = Vagrant::Plugin::V2::Plugin.manager
          plugins = [[:commands, :COMMAND],
            [:communicators, :COMMUNICATOR],
            [:guests, :GUEST],
            [:hosts, :HOST],
            [:providers, :PROVIDER],
            [:provisioners, :PROVISIONER],
            [:synced_folders, :SYNCED_FOLDER]].map do |method, const|
            plugin_manager.send(method).map do |k, v|
              Hashicorp::Vagrant::Plugin.new(name: k, type: Hashicorp::Vagrant::Plugin::Type.const_get(const))
            end
          end.flatten
          Hashicorp::Vagrant::GetPluginsResponse.new(
            plugins: plugins
          )
        end

        def parse_vagrantfile(req, _unused_call)
          path = req.path
          raw = File.read(path)

          # Load up/parse the vagrantfile
          config_loader = Vagrant::Config::Loader.new(
            Vagrant::Config::VERSIONS, Vagrant::Config::VERSIONS_ORDER)
          config_loader.set(:root, path)
          v = Vagrant::Vagrantfile.new(config_loader, [:root])
          LOG.debug("loaded vagrantfile")

          machine_configs = []
          # Get the config for each machine
          v.machine_names.each do |mach|
            LOG.debug("loading machine config for #{mach}")
            machine_info = v.machine_config(mach, nil, nil, false)
            root_config = machine_info[:config]
            vm_config = root_config.vm

            LOG.debug("extracting config.ssh")
            # Get config.ssh.*
            config_ssh_proto = extract_communicator(CONFIG_SSH_CLS, root_config.ssh)

            LOG.debug("extracting config.winrm")
            # Get config.winrm.*
            config_winrm_proto = extract_communicator(CONFIG_WINRM_CLS, root_config.winrm)

            LOG.debug("extracting config.winssh")
            #Get config.winssh.*
            config_winssh_proto = extract_communicator(CONFIG_WINSSH_CLS, root_config.winssh)

            LOG.debug("extracting config.vagrant")
            # Get config.vagrant.*
            config_vagrant_proto = extract_config_component(CONFIG_VAGRANT_CLS, root_config.vagrant)

            LOG.debug("extracting config.vm")
            # Get's config.vm.*
            config_vm_proto = extract_config_component(CONFIG_VM_CLS, vm_config)
            LOG.debug("extracting provisioners")
            extract_provisioners(config_vm_proto.provisioners, vm_config.provisioners)
            LOG.debug("extracting network")
            extract_network(config_vm_proto.networks, vm_config.networks)
            LOG.debug("extracting synced folder")
            extract_synced_folders(config_vm_proto.synced_folders, vm_config.synced_folders)
            LOG.debug("extracting provider")
            extract_provider(config_vm_proto.providers, vm_config)
            LOG.debug("done loading machine config for #{mach}")

            plugin_configs = []
            root_config.__internal_state["keys"].each do |name, config|
              # A builtin plugin
              # TODO: find a better way to check the module
              next if config.class.to_s.split("::")[0] == "VagrantPlugins"
              plugin_configs << extract_plugin_config(name, config)
            end

            machine_configs << Hashicorp::Vagrant::Sdk::Vagrantfile::MachineConfig.new(
              name: mach.to_s,
              config_vm: config_vm_proto,
              config_vagrant: config_vagrant_proto,
              config_ssh: config_ssh_proto,
              config_winrm: config_winrm_proto,
              config_winssh: config_winssh_proto,
              plugin_configs: plugin_configs
            )
          end

          vagrantfile = Hashicorp::Vagrant::Sdk::Vagrantfile::Vagrantfile.new(
            path: path,
            raw: raw,
            current_version: Vagrant::Config::CURRENT_VERSION,
            machine_configs: machine_configs,
          )
          LOG.debug("vagrantfile parsed!")
          Hashicorp::Vagrant::ParseVagrantfileResponse.new(
            vagrantfile: vagrantfile
          )
        end

        def stringify_symbols(m)
          m.each do |k,v|
            if v.is_a?(Hash)
              # All keys need to be strings
              v.transform_keys!{|sk| sk.to_s}
              stringify_symbols(v)
              next
            end
            if v.is_a?(Array)
              v.map!{|sk| sk.is_a?(Symbol) ? sk.to_s : sk}
              stringify_symbols(v)
              next
            end
            k = k.to_s if k.is_a?(Symbol)
            m[k] = v.to_s if v.is_a?(Symbol)
          end
        end

        def clean_up_config_object(config)
          protoize = config
          stringify_symbols(protoize)
          # Remove variables that are internal
          protoize.delete_if{|k,v| k.start_with?("_") }
          protoize
        end

        def extract_provisioners(target, provisioners)
          provisioners.each do |c|
            proto = PROVISION_PROTO_CLS.new()
            c.instance_variables_hash.each do |k, v|
              begin
                if k == "config"
                  protoize = clean_up_config_object(c.config.instance_variables_hash)
                  config_struct = Google::Protobuf::Struct.from_hash(protoize)
                  config_any = Google::Protobuf::Any.pack(config_struct)
                  proto.config = config_any
                  next
                end
                if !v.nil?
                  v = v.to_s if v.is_a?(Symbol)
                  proto.send("#{k}=", v)
                end
              rescue NoMethodError
                # this is ok
              end
            end
            target << proto
          end
        end

        # Network configs take the form
        # [
        #   [:type, {:id=>"tcp8080", ...}], ...
        # ]
        def extract_network(target, networks)
          networks.each do |n|
            type = n[0]
            opts = n[1]
            network_proto = NETWORK_PROTO_CLS.new(type: type, id: opts.fetch(:id, ""))
            opts.delete(:id)
            opts.transform_keys!(&:to_s)
            config_struct = Google::Protobuf::Struct.from_hash(opts)
            config_any = Google::Protobuf::Any.pack(config_struct)
            network_proto.config = config_any
            target << network_proto
          end
        end

        # Providers take the form
        # {
        #   :type=> #<VagrantPlugins::PluginClass::Config:Object>, ...
        # }
        def extract_provider(target, vm_config)
          #WARNING: hacks ahead
          vm_config.define_singleton_method(:compiled_provider_configs) do
            return @__compiled_provider_configs
          end

          vm_config.compiled_provider_configs.each do |type, config|
            c = clean_up_config_object(config.instance_variables_hash)

            provider_proto = PROVIDER_PROTO_CLS.new(type: type)
            config_struct = Google::Protobuf::Struct.from_hash(c)
            config_any = Google::Protobuf::Any.pack(config_struct)
            provider_proto.config = config_any
            target << provider_proto
          end
        end 

        # Synced folders take the form of a hash map
        # {
        #   "name"=>{:type=>:rsync, ...},  ...
        # },
        def extract_synced_folders(target, synced_folders)
          synced_folders.each do |k,v|
            sf_proto = SYNCED_FOLDER_PROTO_CLS.new()

            # Need to set source and destination since they don't exactly map
            sf_proto.source = v[:hostpath]
            sf_proto.destination = v[:guestpath]

            # config_opts keep track of the config options specific to the synced
            # folder type. They are in the form `type`__`option`
            config_opts = {}

            v.each do |opt, val|
              # already accounted for above
              next if ["guestpath", "hostpath"].include?(opt.to_s)

              # match the synced folder specific options and store them in the
              # config_opts
              if opt.to_s.match(/#{v[:type]}__/)
                config_opts[opt.to_s.split("__")[1]] = val
                next
              end

              sf_proto.send("#{opt.to_s}=", val)
            end
            config_struct = Google::Protobuf::Struct.from_hash(config_opts)
            config_any = Google::Protobuf::Any.pack(config_struct)
            sf_proto.config = config_any
            target << sf_proto
          end
        end

        def extract_config_component(config_cls, config)
          config_proto = config_cls.new()
          config.instance_variables_hash.each do |k, v|
            # Skip config that has not be set
            next if v.class == Object 

            # Going to deal with these seperately because they are more involved
            next if ["provisioners", "networks", "synced_folders", "disks", "cloud_init_configs"].include?(k)

            # Skip all variables that are internal
            next if k.start_with?("_")

            if v.nil? 
              # If v is nil, set it to the default value defined by the proto
              v = config_proto.send(k)
            end

            if v.is_a?(Range)
              v = v.to_a
            end

            if v.is_a?(Hash)
              m = config_proto.send(k)
              v.each do |k2,v2|
                m[k2] = v2
              end 
              v = m
            end

            if v.is_a?(Array)
              m = config_proto.send(k)
              v.each do |v2|
                m << v2
              end 
              v = m
            end

            begin
              config_proto.send("#{k}=", v)
            rescue NoMethodError
              # Reach here when Hashicorp::Vagrant::VagrantfileComponents::ConfigVM does not
              # have a config variable for one of the instance methods. This is ok.
            end
          end
          config_proto
        end

        def extract_communicator(config_cls, config)
          protoize = config.instance_variables_hash
          protoize.map do |k,v|
            if v.is_a?(Vagrant.plugin("2", :config))
              # Get embedded default struct
              hashed_config = v.instance_variables_hash
              hashed_config.delete_if{|k,v| k.start_with?("_") }
              protoize[k] = hashed_config
            end
          end
          protoize = clean_up_config_object(protoize)
          config_struct = Google::Protobuf::Struct.from_hash(protoize)
          config_any = Google::Protobuf::Any.pack(config_struct)
          config_cls.new(config: config_any)
        end

        def extract_plugin_config(type, config)
          protoize = config.instance_variables_hash
          protoize = clean_up_config_object(protoize)
          config_struct = Google::Protobuf::Struct.from_hash(protoize)
          config_any = Google::Protobuf::Any.pack(config_struct)
          GENERAL_CONFIG_CLS.new(type: type, config: config_any)
        end
      end
    end
  end
end
