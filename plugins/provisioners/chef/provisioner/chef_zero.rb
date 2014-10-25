require 'pathname'
require 'vagrant/util/subprocess'

require File.expand_path('../chef_solo', __FILE__)

module VagrantPlugins
  module Chef
    module Provisioner
      # This class validates that we are using the `chef-zero` binary which is
      # merely implemented on top of `chef-client` as local mode.
      class ChefZero < ChefSolo
        def configure(root_config)
          @clients_folders = expanded_folders(@config.users_path, 'clients')
          @users_folders = expanded_folders(@config.users_path, 'users')

          share_folders(root_config, 'cscl', @clients_folders)
          share_folders(root_config, 'csu', @users_folders)

          raise ChefError, :local_mode unless @config.local_mode
          super
        end

        def provision
          [@clients_folders, @users_folders].each do |folders|
            folders.each do |type, local_path, remote_path|
              # We only care about checking folders that have a local path, meaning
              # they were shared from the local machine, rather than assumed to
              # exist on the VM.
              check << remote_path if local_path
            end            
          end

          super
        end

        def chef_binary_path(binary)
          return 'chef-client' unless @config.binary_path
          return File.join(@config.binary_path, 'chef-client')
        end
      end
    end
  end
end
