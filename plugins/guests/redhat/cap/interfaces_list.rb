module VagrantPlugins
  module GuestRedHat
    module Cap
      class InterfacesList
        def self.interfaces_list(machine)
          version =  String.new
          machine.communicate.sudo("cat /etc/redhat-release | sed -e 's/.*release\ //' | cut -f1 -d' '") do |_, result|
            # Only care about the major version for now
            version = result.split('.').first
          end
          
          interface_names = Array.new

          # In theory this would work with even older versions as dmesg has been relatively static for a long time
          if version.to_i < 6
            machine.communicate.sudo("dmesg | cut -f2 -d: | sed -e 's/^\ //' | sed -e 's/\ .*$//' | grep eth") do |_, result|
              # It has two results ? - Quick hack to compensate
              interface_names = result.split("\n").uniq.sort if interface_names.empty?
            end
          else
            machine.communicate.sudo("biosdevname -d | grep Kernel | cut -f2 -d: | sed -e 's/ //;'") do |_, result|
              # The previous had two results.  This one never has.  Do the same check for now.
              interface_names = result.split("\n") if interface_names.empty?
            end
          end
          
          return interface_names
        end
      end
    end
  end
end