require "vagrant"

module VagrantPlugins
  module GuestCentos
    class Plugin < Vagrant.plugin("2")
      name "CentOS guest"
      description "CentOS guest support."

      guest(:centos, :redhat) do
        require_relative "guest"
        Guest
      end

      guest_capability(:centos, :flavor) do
        require_relative "cap/flavor"
        Cap::Flavor
      end
    end
  end
end
