module Vagrant
  class Config
    class PackageConfig < Base
      Config.configures :package, self

      attr_accessor :name
    end
  end
end
