# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require "vagrant/util/shell_quote"

module VagrantPlugins
  module GuestOpenWrt
    module Cap
      class RemovePublicKey
        def self.remove_public_key(machine, contents)
          contents = contents.chomp
          contents = Vagrant::Util::ShellQuote.escape(contents, "'")

          machine.communicate.tap do |comm|
            comm.execute <<~EOH
              if test -f /etc/dropbear/authorized_keys ; then
                sed -i '/^.*#{contents}.*$/d' /etc/dropbear/authorized_keys
              fi
            EOH
          end
        end
      end
    end
  end
end
