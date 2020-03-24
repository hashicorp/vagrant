require "vagrant/util/hyperv_daemons"

module VagrantPlugins
  module GuestLinux
    module Cap
      class HypervDaemons
        extend Vagrant::Util::HypervDaemons
      end
    end
  end
end
