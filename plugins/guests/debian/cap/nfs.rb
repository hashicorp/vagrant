# Copyright IBM Corp. 2010, 2025
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module GuestDebian
    module Cap
      class NFS
        def self.nfs_client_install(machine)
          comm = machine.communicate
          comm.sudo <<-EOH.gsub(/^ {12}/, '')
            apt-get -yqq update
            DEBIAN_FRONTEND=noninteractive apt-get -yqq install nfs-common portmap
            exit $?
          EOH
        end
      end
    end
  end
end
