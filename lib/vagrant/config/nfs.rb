module Vagrant
  module Config
    class NFSConfig < Base
      attr_accessor :map_uid
      attr_accessor :map_gid
      attr_accessor :readonly
    end
  end
end
