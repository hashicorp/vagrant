require "tempfile"

require "vagrant/util/template_renderer"

module VagrantPlugins
  module GuestDarwin
    module Cap
      class ConfigureNetworks
        include Vagrant::Util

        def self.configure_networks(machine, networks)
          # Slightly different than other plugins, using the template to build commands 
          # rather than templating the files.

          machine.communicate.sudo("networksetup -detectnewhardware")
          machine.communicate.sudo("networksetup -listnetworkserviceorder > /tmp/vagrant.interfaces")
          tmpints = File.join(Dir.tmpdir, File.basename("#{machine.id}.interfaces"))
          machine.communicate.download("/tmp/vagrant.interfaces",tmpints)

          devlist = []
          ints = ::IO.read(tmpints)
          ints.split(/\n\n/m).each do |i|
            if i.match(/Hardware/) and not i.match(/Ethernet/).nil?
              devmap = {}
              # Ethernet, should be 2 lines, 
              # (3) Thunderbolt Ethernet
              # (Hardware Port: Thunderbolt Ethernet, Device: en1)

              # multiline, should match "Thunderbolt Ethernet", "en1"
              devicearry = i.match(/\([0-9]+\) (.+)\n.*Device: (.+)\)/m)
              devmap[:interface] = devicearry[2]
              devmap[:service] = devicearry[1]
              devlist << devmap
            end
          end
          File.delete(tmpints)

          networks.each do |network|
            service_name = devlist[network[:interface]][:service]
            if network[:type].to_sym == :static
              command = "networksetup -setmanual \"#{service_name}\" #{network[:ip]} #{network[:netmask]}"
            elsif network[:type].to_sym == :dhcp
              command = "networksetup -setdhcp \"#{service_name}\""
            end

            machine.communicate.sudo(command)
          end
        end
      end
    end
  end
end
