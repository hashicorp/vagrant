require "vagrant/util/shell_quote"

module VagrantPlugins
  module GuestNetBSD
    module Cap
      class InsertPublicKey
        def self.insert_public_key(machine, contents)
          contents = Vagrant::Util::ShellQuote.escape(contents, "'")
          contents = contents.gsub("\n", "\\n")

          machine.communicate.tap do |comm|
            comm.execute("mkdir -p ~/.ssh")
            comm.execute("chmod 0700 ~/.ssh")
            comm.execute("printf '#{contents}' >> ~/.ssh/authorized_keys")
            comm.execute("chmod 0600 ~/.ssh/authorized_keys")
          end
        end
      end
    end
  end
end
