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
          devmap = {}
          machine.communicate.sudo("networksetup -listnetworkserviceorder > /tmp/vagrant.interfaces")
          tmpints = File.join(Dir.tmpdir, "#{machine.id}.interfaces")
          machine.communicate.download("/tmp/vagrant.interfaces",tmpints)
          ints = IO.read(tmpints)
          ints.split(/\n\n/m).each do |i|
              if i.match(/Hardware/) and not i.match(/Ethernet/).nil?
                  # Ethernet, should be 2 lines, 
                  # (3) Thunderbolt Ethernet
                  # (Hardware Port: Thunderbolt Ethernet, Device: en1)
                  devicearry = i.match(/Hardware Port: (.+), Device: en(.+)\)/)
                  devmap[devicearry[2]] = devicearry[1]
              end
          end
          networks.each do |network|


              if network[:type].to_sym == :static
                  # network seems 1 indexed - skip NAT interface (en0) also en1 because it seems to not *really* exist on virtualbox?
                  intnum = network[:interface] + 1
                  puts "Network - #{intnum}"
              command = "networksetup -setmanual \"#{devmap[intnum.to_s]}\" #{network[:ip]} #{network[:netmask]} #{network[:gateway]}"

              elsif network[:type].to_sym == :dhcp
                command = "networksetup -setdhcp \"#{devmap[options[:interface]]}\""

              end

            machine.communicate.sudo("#{command}")
          end
        end
      end
    end
  end
end
