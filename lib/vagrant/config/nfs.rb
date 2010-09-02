module Vagrant
  class Config
    class NFSConfig < Base
      Config.configures :nfs, self

      attr_accessor :map_uid
      attr_accessor :map_gid
    end
  end
end
