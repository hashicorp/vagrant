#-------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the MIT License.
#--------------------------------------------------------------------------

module VagrantPlugins
  module HyperV
    module Driver
      lib_path = Pathname.new(File.expand_path("../driver", __FILE__))
      autoload :Base, lib_path.join("base")
    end
  end
end
