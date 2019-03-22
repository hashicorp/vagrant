require "tempfile"

require_relative "../../../../lib/vagrant/util/template_renderer"

module VagrantPlugins
  module GuestCoreOS
    module Cap
      class ConfigureNetworks
        extend Vagrant::Util::GuestInspection::Linux

        DEFAULT_ENVIRONMENT_IP = "127.0.0.1".freeze

        def self.configure_networks(machine, networks)
          cloud_config = {}
          # Locate configured IP addresses to drop in /etc/environment
          # for export. If no addresses found, fall back to default
          public_ip = catch(:public_ip) do
            machine.config.vm.networks.each do |type, opts|
              next if type != :public_network
              throw(:public_ip, opts[:ip]) if opts[:ip]
            end
            DEFAULT_ENVIRONMENT_IP
          end
          private_ip = catch(:private_ip) do
            machine.config.vm.networks.each do |type, opts|
              next if type != :private_network
              throw(:private_ip, opts[:ip]) if opts[:ip]
            end
            public_ip
          end
          cloud_config["write_files"] = [
            {"path" => "/etc/environment",
              "content" => "COREOS_PUBLIC_IPV4=#{public_ip}\nCOREOS_PRIVATE_IPV4=#{private_ip}"}
          ]

          # Generate configuration for any static network interfaces
          # which have been defined
          interfaces = machine.guest.capability(:network_interfaces)
          units = networks.map do |network|
            iface = network[:interface].to_i
            unit_name = "50-vagrant#{iface}.network"
            device = interfaces[iface]
            if network[:type].to_s == "dhcp"
              network_content = "DHCP=yes"
            else
              prefix = IPAddr.new("255.255.255.255/#{network[:netmask]}").to_i.to_s(2).count("1")
              address = "#{network[:ip]}/#{prefix}"
              network_content = "Address=#{address}"
            end
            {"name" => unit_name,
              "runtime" => "no",
              "content" => "[Match]\nName=#{device}\n[Network]\n#{network_content}"}
          end
          cloud_config["coreos"] = {"units" => units.compact}

          # Upload configuration and apply
          file = Tempfile.new("vagrant-coreos-networks")
          file.puts("#cloud-config\n")
          file.puts(cloud_config.to_yaml)
          file.close

          dst = "/var/tmp/networks.yml"
          svc_path = dst.tr("/", "-")[1..-1]
          machine.communicate.upload(file.path, dst)
          machine.communicate.sudo("systemctl start system-cloudinit@#{svc_path}.service")
        end
      end
    end
  end
end
