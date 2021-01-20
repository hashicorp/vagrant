
require "vagrant/plugin/v2/plugin"
require "vagrant/vagrantfile"
require "vagrant/box_collection"
require "vagrant/config"
require "pathname"

require 'vagrant/proto/gen/ruby-server_pb'
require 'vagrant/proto/gen/ruby-server_services_pb'
require 'google/protobuf/well_known_types'

module VagrantPlugins
  module CommandServe
    module Service
      class InternalService < Hashicorp::Vagrant::RubyVagrant::Service
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
          vagrantfile_path = req.path
          raw = File.read(vagrantfile_path)

          # Load up/parse the vagrantfile
          config_loader = Vagrant::Config::Loader.new(
            Vagrant::Config::VERSIONS, Vagrant::Config::VERSIONS_ORDER)
          config_loader.set(:root, vagrantfile_path)
          v = Vagrant::Vagrantfile.new(config_loader, [:root])

          sc = v.config.ssh
          ssh_config = Hashicorp::Vagrant::Sdk::SSHInfo.new(
            port: sc.guest_port.to_s, ssh_command: sc.shell
          )
          wc = v.config.winrm
          winrm_config = Hashicorp::Vagrant::Sdk::WinrmInfo.new(
            username: wc.username, password: wc.password, host: wc.host,
            port: wc.port, guest_port: wc.guest_port)
          communicators = [
            Hashicorp::Vagrant::Communicator.new(
              name: "ssh", config: Google::Protobuf::Any.pack(ssh_config)
            ),
            Hashicorp::Vagrant::Communicator.new(
              name: "winrm", config: Google::Protobuf::Any.pack(winrm_config)
            ),
          ]

          machine_configs = []
          # Get the config for each machine
          v.machine_names.each do |mach|
            machine_info = v.machine_config(mach, nil, nil)
            root_config = machine_info[:config]
            config = root_config.vm
            machine_configs << Hashicorp::Vagrant::MachineConfig.new(
              name: mach.to_s,
              box: config.box,
              provisioners: []
            )
          end

          vagrantfile = Hashicorp::Vagrant::Vagrantfile.new(
            path: vagrantfile_path,
            raw: raw,
            current_version: Vagrant::Config::CURRENT_VERSION,
            machine_configs: machine_configs,
            communicators: communicators,
          )
          Hashicorp::Vagrant::ParseVagrantfileResponse.new(
            vagrantfile: vagrantfile
          )
        end
      end
    end
  end
end
