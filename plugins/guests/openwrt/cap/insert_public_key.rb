# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require "vagrant/util/shell_quote"

module VagrantPlugins
  module GuestOpenWrt
    module Cap
      class InsertPublicKey
        def self.insert_public_key(machine, contents)
          contents = contents.chomp
          contents = Vagrant::Util::ShellQuote.escape(contents, "'")

          machine.communicate.tap do |comm|
            comm.execute <<~EOH
              printf '#{contents}\\n' >> /etc/dropbear/authorized_keys
            EOH
          end
        end
      end
    end
  end
end
