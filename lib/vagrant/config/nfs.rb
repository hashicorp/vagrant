module Vagrant
  module Config
    class NFSConfig < Base
      attr_accessor :map_uid
      attr_accessor :map_gid
    end
  end
end
