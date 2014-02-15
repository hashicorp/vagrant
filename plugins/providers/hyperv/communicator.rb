module VagrantPlugins
  module HyperV
    module Communicator
      lib_path = Pathname.new(File.expand_path("../communicator", __FILE__))
      autoload :SSH, lib_path.join("ssh")
    end
  end
end
