module VagrantPlugins
  module GuestAmazon
    module Cap
      class Flavor
        def self.flavor(machine)
          # Amazon AMI is a frankenstien RHEL, mainly based on 6
          # Maybe in the future if they incoporate RHEL 7 elements
          # this should be extended to read /etc/os-release or similar
          return :rhel
        end
      end
    end
  end
end
