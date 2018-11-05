require "vagrant/util/shell_quote"

module VagrantPlugins
  module GuestHaiku
    module Cap
      class RemovePublicKey
        def self.remove_public_key(machine, contents)
          contents = contents.chomp
          contents = Vagrant::Util::ShellQuote.escape(contents, "'")

          machine.communicate.tap do |comm|
            if comm.test("test -f $(finddir B_USER_SETTINGS_DIRECTORY)/ssh/authorized_keys")
              comm.execute(
                "sed -i '/^.*#{contents}.*$/d' $(finddir B_USER_SETTINGS_DIRECTORY)/ssh/authorized_keys")
            end
          end
        end
      end
    end
  end
end
