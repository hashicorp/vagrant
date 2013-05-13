module Vagrant
  module Config
    module V2
      autoload :DummyConfig, "vagrant/config/v2/dummy_config"
      autoload :Loader, "vagrant/config/v2/loader"
      autoload :Root,   "vagrant/config/v2/root"
    end
  end
end
