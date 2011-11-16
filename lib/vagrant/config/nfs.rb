module Vagrant
  class Config
    class NFSConfig < Base
      configures :nfs

      attr_accessor :map_uid
      attr_accessor :map_gid
      attr_accessor :version
    end
  end
end
