module Vagrant
  class Config
    class PackageConfig < Base
      configures :package

      attr_accessor :name
    end
  end
end
