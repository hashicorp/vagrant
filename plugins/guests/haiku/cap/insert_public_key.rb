require "vagrant/util/shell_quote"

module VagrantPlugins
  module GuestHaiku
    module Cap
      class InsertPublicKey
        def self.insert_public_key(machine, contents)
          contents = contents.chomp
          contents = Vagrant::Util::ShellQuote.escape(contents, "'")

          machine.communicate.tap do |comm|
            comm.execute("mkdir -p $(finddir B_USER_SETTINGS_DIRECTORY)/ssh")
            comm.execute("chmod 0700 $(finddir B_USER_SETTINGS_DIRECTORY)/ssh")
            comm.execute("printf '#{contents}\\n' >> $(finddir B_USER_SETTINGS_DIRECTORY)/ssh/authorized_keys")
            comm.execute("chmod 0600 $(finddir B_USER_SETTINGS_DIRECTORY)/ssh/authorized_keys")
          end
        end
      end
    end
  end
end
