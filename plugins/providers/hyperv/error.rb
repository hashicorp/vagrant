#-------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the MIT License.
#--------------------------------------------------------------------------

module VagrantPlugins
  module HyperV
    module Error
      lib_path = Pathname.new(File.expand_path("../error", __FILE__))
      autoload :SubprocessError, lib_path.join("subprocess_error")
    end
  end
end
