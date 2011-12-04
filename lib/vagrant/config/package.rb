module Vagrant
  module Config
    class PackageConfig < Base
      configures :package

      attr_accessor :name
    end
  end
end
