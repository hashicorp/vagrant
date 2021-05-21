require "vagrant"
require "vagrant/plugin/v2/plugin"
require "vagrant/vagrantfile"
require "vagrant/box_collection"
require "vagrant/config"
require "pathname"
require 'google/protobuf/well_known_types'

require_relative "./plugins/commands/serve/command"

vagrantfile_path = "/Users/sophia/project/vagrant-ruby/Vagrantfile"

PROVIDER_PROTO_CLS = Hashicorp::Vagrant::VagrantfileComponents::Provider
PROVISION_PROTO_CLS = Hashicorp::Vagrant::VagrantfileComponents::Provisioner
SYNCED_FOLDER_PROTO_CLS = Hashicorp::Vagrant::VagrantfileComponents::SyncedFolder
NETWORK_PROTO_CLS = Hashicorp::Vagrant::VagrantfileComponents::Network

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
    v = v.to_s if v.is_a?(Symbol)
  end
end

def extract_component(target_cls, target, vagrant_config)
  vagrant_config.each do |c|
    proto = target_cls.new()
    c.instance_variables_hash.each do |k, v|
      begin
        if k == "config"
          config_struct = Google::Protobuf::Struct.from_hash(c.config.instance_variables_hash)
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
    c = config.instance_variables_hash
    stringify_symbols(c)
    c.delete("__invalid_methods")

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
    # TODO: Get config.ssh, config.winrm, config.winssh, config.vagrant from
    #       root config
    root_config = machine_info[:config]
    vm_config = root_config.vm

    config_vm_proto = Hashicorp::Vagrant::VagrantfileComponents::ConfigVM.new()
    vm_config.instance_variables_hash.each do |k, v|
      # Skip config that has not be set
      next if v.class == Object 

      # Going to deal with these seperately because they are more involved
      next if ["provisioners", "networks", "synced_folders", "disks", "cloud_init_configs"].include?(k)

      # Skip all variables that are internal
      next if k.start_with?("_")

      if v.nil? 
        # If v is nil, set it to the default value defined by the proto
        v = config_vm_proto.send(k)
      end

      if v.is_a?(Range)
        v = v.to_a
      end

      if v.is_a?(Hash)
        m = config_vm_proto.send(k)
        v.each do |k,v2|
          m[k] = v2
        end 
        v = m
      end

      if v.is_a?(Array)
        m = config_vm_proto.send(k)
        v.each do |v2|
          m << v2
        end 
        v = m
      end

      begin
        config_vm_proto.send("#{k}=", v)
      rescue NoMethodError
        # Reach here when Hashicorp::Vagrant::VagrantfileComponents::ConfigVM does not
        # have a config variable for one of the instance methods. This is ok.
      end
    end


    extract_component(PROVISION_PROTO_CLS, config_vm_proto.provisioners, vm_config.provisioners)
    extract_network(config_vm_proto.networks, vm_config.networks)
    extract_synced_folders(config_vm_proto.synced_folders, vm_config.synced_folders)
    extract_provider(config_vm_proto.providers, vm_config)

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
  Hashicorp::Vagrant::ParseVagrantfileResponse.new(
    vagrantfile: vagrantfile
  )
end

def proto_to_provisioner(vagrantfile_proto, validate=false)
  # Just grab the first provisioner
  vagrantfile_proto.machine_configs[0].config_vm.provisioners.each do |p| 
    plugin = Vagrant.plugin("2").manager.provisioners[p.type.to_sym]
    if plugin.nil?
      puts "No plugin available for #{p.type}\n"
      next
    end
    raw_config = p.config.unpack(Google::Protobuf::Struct).to_h
    puts p.type
    puts raw_config
    puts "\n"
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
