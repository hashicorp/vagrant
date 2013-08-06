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
          ints = IO.read(tmpints)
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
          puts devlist

          networks.each do |network|
            intnum = network[:interface]
            puts network[:interface]
            puts network[:type]
            if network[:type].to_sym == :static
              # network seems 1 indexed - skip NAT interface (en0) also en1 because it seems to not *really* exist on virtualbox?
              command = "networksetup -setmanual \"#{devlist[intnum][:service]}\" #{network[:ip]} #{network[:netmask]}"

            elsif network[:type].to_sym == :dhcp
              command = "networksetup -setdhcp \"#{devlist[intnum][:service]}\""

            end

            machine.communicate.sudo(command)
          end
        end
      end
    end
  end
end
