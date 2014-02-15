#-------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the MIT License.
#--------------------------------------------------------------------------
module VagrantPlugins
  module HyperV
    module HostShare
      class Config < Vagrant.plugin("2", :config)
        attr_accessor :username, :password

        def errors
          @errors
        end

        def validate
          @errors = []
          if username.nil?
            @errors << "Please configure a Windows user account to share folders"
          end
          if password.nil?
            @errors << "Please configure a Windows user account password to share folders"
          end
        end

        def valid_config?
          validate
          errors.empty?
        end

      end
    end
  end
end
