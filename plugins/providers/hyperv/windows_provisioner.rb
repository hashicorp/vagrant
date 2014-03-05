#-------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the MIT License.
#--------------------------------------------------------------------------
module VagrantPlugins
  module HyperV
    module WindowsProvisioner
      lib_path = Pathname.new(File.expand_path("../windows_provisioner", __FILE__))
      autoload :Shell, lib_path.join("shell")
      autoload :Puppet, lib_path.join("puppet")
    end
  end
end
