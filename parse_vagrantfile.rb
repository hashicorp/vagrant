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
    machine_info = v.machine_config(mach, nil, nil)
    root_config = machine_info[:config]
    vm_config = root_config.vm
    provisioners = []
    vm_config.provisioners.each do |p|
    config_struct = Google::Protobuf::Struct.from_hash(p.config.instance_variables_hash)
    config_any = Google::Protobuf::Any.pack(config_struct)
    provisioners << Hashicorp::Vagrant::VagrantfileComponents::Provisioner.new(
      name: p.name,
      type: p.type.to_s,
      before: p.before,
      after: p.after,
      communicator_required: p.communicator_required,
      config: config_any,
    )
  end
    machine_configs << Hashicorp::Vagrant::VagrantfileComponents::MachineConfig.new(
      name: mach.to_s,
      config_vm: Hashicorp::Vagrant::VagrantfileComponents::ConfigVM.new(
        box: vm_config.box,
        provisioners: provisioners,
      ),
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

def proto_to_vagrantfile(vagrantfile_proto)
  puts "Vagrant.configure(\"2\") do |config|"
  vagrantfile_proto.machine_configs.each do |m|
    puts "config.vm.define \"#{m.name}\" do |c|"
    puts "  c.vm.box = \"#{m.config_vm.box}\""
    m.config_vm.provisioners.each do |p|
      provisioner_config = p.config.unpack( Google::Protobuf::Struct).to_h
      puts "  c.vm.provision \"#{p.type}\" do |s|"
      provisioner_config.each do |key, val|
        puts "    s.#{key} = \"#{val}\""
      end
      puts "  end"
    end
    puts "end\n"
  end
  puts "end"
end

def proto_to_provisioner(vagrantfile_proto)
  # Just grab the first provisioner
  p = vagrantfile_proto.machine_configs[0].config_vm.provisioners[0]
  plugin = Vagrant.plugin("2").manager.provisioners[p.type.to_sym]
  plugin_config = Vagrant.plugin("2").manager.provisioner_configs[p.type.to_sym]
  # Create a new config
  config = plugin_config.new
  # Unpack the config from the proto
  raw_config = p.config.unpack( Google::Protobuf::Struct).to_h
  # Set config
  config.set_options(raw_config)
  # Ensure config is valid
  config.validate("machine")
  # Create new provisioner
  provisioner = plugin.new("machine", config)

  puts provisioner
end

parse_vagrantifle_response = parse_vagrantfile(vagrantfile_path)
proto_to_provisioner(parse_vagrantifle_response.vagrantfile)
