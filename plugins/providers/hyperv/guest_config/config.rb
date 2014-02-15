#-------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the MIT License.
#--------------------------------------------------------------------------
module VagrantPlugins
  module HyperV
    module GuestConfig
      class Config < Vagrant.plugin("2", :config)
        attr_accessor :username, :password

        def errors
          @errors
        end

        def validate
          @errors = []
          if username.nil?
            @errors << "Please configure a Guest VM's username"
          end
          if password.nil?
            @errors << "Please configure a Guest VM's password"
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
