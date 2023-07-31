# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require "vagrant/util/shell_quote"

module VagrantPlugins
  module GuestSolaris
    module Cap
      class RemovePublicKey
        def self.remove_public_key(machine, contents)
          # "sed -i" is specific to GNU sed and is not a posix standard option
          contents = contents.chomp
          contents = Vagrant::Util::ShellQuote.escape(contents, "'")

          machine.communicate.tap do |comm|
            if comm.test("test -f ~/.ssh/authorized_keys")
              comm.execute(
                "cp ~/.ssh/authorized_keys ~/.ssh/authorized_keys.temp && sed '/^.*#{contents}.*$/d' ~/.ssh/authorized_keys.temp > ~/.ssh/authorized_keys && rm ~/.ssh/authorized_keys.temp")
            end
          end
        end
      end
    end
  end
end
