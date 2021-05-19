require "vagrant"
require "vagrant/plugin/v2/plugin"
require "vagrant/vagrantfile"
require "vagrant/box_collection"
require "vagrant/config"
require "pathname"
require 'google/protobuf/well_known_types'

require_relative "./plugins/commands/serve/command"

vagrantfile_path = "/Users/sophia/project/vagrant-ruby/Vagrantfile"

def parse_vagrantfile(path)
  # Load up/parse the vagrantfile
  config_loader = Vagrant::Config::Loader.new(
    Vagrant::Config::VERSIONS, Vagrant::Config::VERSIONS_ORDER)
  config_loader.set(:root, path)
  v = Vagrant::Vagrantfile.new(config_loader, [:root])

  machine_configs = []
  # Get the config for each machine
  v.machine_names.each do |mach|
    machine_info = v.machine_config(mach, nil, nil, false)
    root_config = machine_info[:config]
    vm_config = root_config.vm
    
    config_vm_proto = Hashicorp::Vagrant::VagrantfileComponents::ConfigVM.new()
    vm_config.instance_variables_hash.each do |k, v|
      if v.class == Object 
        # Skip config that has not be set
        next
      end
      if k == "provisioners"
        vm_config.provisioners.each do |p|
          provisioner_proto = Hashicorp::Vagrant::VagrantfileComponents::Provisioner.new()
          p.instance_variables_hash.each do |k, v|
            begin
              if k == "config"
                config_struct = Google::Protobuf::Struct.from_hash(p.config.instance_variables_hash)
                config_any = Google::Protobuf::Any.pack(config_struct)
                provisioner_proto.config = config_any
                next
              end
              if !v.nil?
                v = v.to_s if v.is_a?(Symbol)
                provisioner_proto.send("#{k}=", v)
              end
            rescue NoMethodError
              # this is ok
            end
          end
          config_vm_proto.provisioners << provisioner_proto
        end
        next
      end
      if ["networks", "synced_folders"].include?(k)
        next
      end
      begin
        config_vm_proto.send("#{k}=", v)
      rescue NoMethodError
        # Reach here when Hashicorp::Vagrant::VagrantfileComponents::ConfigVM does not
        # have a config variable for one of the instance methods. This is ok.
      end
    end
    machine_configs << Hashicorp::Vagrant::VagrantfileComponents::MachineConfig.new(
      name: mach.to_s,
      config_vm: config_vm_proto,
    )
  end
  
  vagrantfile = Hashicorp::Vagrant::VagrantfileComponents::Vagrantfile.new(
    path: path,
    # raw: raw,
    current_version: Vagrant::Config::CURRENT_VERSION,
    machine_configs: machine_configs,
  )
  puts vagrantfile
  Hashicorp::Vagrant::ParseVagrantfileResponse.new(
    vagrantfile: vagrantfile
  )
end

def proto_to_provisioner(vagrantfile_proto, validate=false)
  # Just grab the first provisioner
  vagrantfile_proto.machine_configs[0].config_vm.provisioners.each do |p| 
    plugin = Vagrant.plugin("2").manager.provisioners[p.type.to_sym]
    if plugin.nil?
      puts "No plugin available for #{p.type}"
      next
    end
    raw_config = p.config.unpack(Google::Protobuf::Struct).to_h
    # TODO: fetch this config
    #       if it doesn't exist, then pass in generic config
    plugin_config = Vagrant.plugin("2").manager.provisioner_configs[p.type.to_sym]
    # Create a new config
    config = plugin_config.new
    # Unpack the config from the proto
    raw_config = p.config.unpack(Google::Protobuf::Struct).to_h
    # Set config
    config.set_options(raw_config)
    if validate
      # Ensure config is valid
      config.validate("machine")
    end
    # Create new provisioner
    provisioner = plugin.new("machine", config)
  end
end

parse_vagrantifle_response = parse_vagrantfile(vagrantfile_path)
proto_to_provisioner(parse_vagrantifle_response.vagrantfile)
