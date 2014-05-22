require 'tempfile'
require 'ipaddr'

require "vagrant/util/template_renderer"

module VagrantPlugins
  module GuestNixos
    module Cap
      class ConfigureNetworks
        include Vagrant::Util

        def self.configure_networks(machine, networks)
          # set the prefix length.
          networks.each do |network|
            network[:prefix_length] = (network[:netmask] && netmask_to_cidr(network[:netmask]))
          end

          # set the device names.
          assign_device_names(machine, networks)

          # upload the config file
          network_module = TemplateRenderer.render("guests/nixos/network", networks: networks)
          upload(machine, network_module, "/etc/nixos/vagrant-network.nix")
        end

        # Set :device on each network.
        # Attempts to use biosdevname when available to detect interface names,
        # and falls back to ifconfig otherwise.
        def self.assign_device_names(machine, networks)
          if machine.communicate.test("command -v biosdevname")
            # use biosdevname to get info about the interfaces
            interfaces = get_interfaces(machine)
            if machine.provider.capability?(:nic_mac_addresses)
              # find device name by MAC lookup.
              mac_addresses = machine.provider.capability(:nic_mac_addresses)
              networks.each do |network|
                mac_address = mac_addresses[network[:interface]+1]
                interface = interfaces.detect {|nic| nic[:mac_address].gsub(":","") == mac_address} if mac_address
                network[:device] = interface[:kernel] if interface
              end
            else
              # assume interface numbers correspond to (ethN+1).
              networks.each do |network|
                interface = interfaces.detect {|nic| nic[:ethn] == network[:interface]}
                network[:device] = interface[:kernel] if interface
              end
            end
          else
            # assume interface numbers correspond to the order of interfaces.
            interfaces = get_interface_names(machine)
            networks.each do |network|
              network[:device] = interfaces[network[:interface]]
            end
          end
        end

        def self.get_interface_names(machine)
          output = nil
          machine.communicate.execute("ifconfig -a") do |type, result|
            output = result.chomp if type == :stdout
          end
          names = output.scan(/^[^:\s]+/).reject {|name| name =~ /^lo/ }
          names
        end

        # Upload a file.
        def self.upload(machine, content, remote_path)
          local_temp = Tempfile.new("vagrant-upload")
          local_temp.binmode
          local_temp.write(content)
          local_temp.close
          remote_temp = mktemp(machine)
          machine.communicate.upload(local_temp.path, "#{remote_temp}")
          local_temp.delete
          machine.communicate.sudo("mv #{remote_temp} #{remote_path}")
        end

        # Create a temp file.
        def self.mktemp(machine)
          path = nil

          machine.communicate.execute("mktemp --suffix -vagrant-upload") do |type, result|
            path = result.chomp if type == :stdout
          end
          path
        end

        # using biosdevname, get all interfaces as a list of hashes, where:
        #   :kernel      - the kernel's name for the device,
        #   :ethn        - the calculated ethN-style name converted to integer.
        #   :mac_address - the permanent mac address. ethN-style name converted to integer.
        def self.get_interfaces(machine)
          interfaces = []

          # get all adapters, as named by the kernel
          output = nil
          machine.communicate.sudo("biosdevname -d") do |type, result|
            output = result if type == :stdout
          end
          kernel_if_names = output.scan(/Kernel name: ([^\n]+)/).flatten
          mac_addresses   = output.scan(/Permanent MAC: ([^\n]+)/).flatten

          # get ethN-style names
          ethns = []
          kernel_if_names.each do |name|
            machine.communicate.sudo("biosdevname --policy=all_ethN -i #{name}") do |type, result|
              ethns << result.gsub(/[^\d]/,'').to_i if type == :stdout
            end
          end

          # populate the interface list
          kernel_if_names.each_index do |i|
            interfaces << {
              kernel:      kernel_if_names[i],
              ethn:        ethns[i],
              mac_address: mac_addresses[i]
            }
          end

          interfaces
        end

        def self.netmask_to_cidr(mask)
          IPAddr.new(mask).to_i.to_s(2).count("1")
        end
      end
    end
  end
end
