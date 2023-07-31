# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module Chef
    module Cap
      module Linux
        module ChefInstalled
          # Check if Chef is installed at the given version.
          # @return [true, false]
          def self.chef_installed(machine, product, version)
            product_name = product == 'chef-workstation' ? 'chef-workstation' : 'chef'
            verify_bin = product_name == 'chef-workstation' ? 'chef' : 'chef-client'
            verify_path = "/opt/#{product_name}/bin/#{verify_bin}"
            command = "test -x #{verify_path}"

            if version != :latest
              command << "&& #{verify_path} --version | grep '#{version}'"
            end

            machine.communicate.test(command, sudo: true)
          end
        end
      end
    end
  end
end
