module Vagrant
  module Config
    module V1
      autoload :DummyConfig, "vagrant/config/v1/dummy_config"
      autoload :Loader, "vagrant/config/v1/loader"
      autoload :Root,   "vagrant/config/v1/root"
    end
  end
end
