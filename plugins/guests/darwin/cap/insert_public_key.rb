require "vagrant/util/shell_quote"

module VagrantPlugins
  module GuestDarwin
    module Cap
      class InsertPublicKey
        def self.insert_public_key(machine, contents)
          contents = contents.chomp
          contents = Vagrant::Util::ShellQuote.escape(contents, "'")

          machine.communicate.tap do |comm|
            comm.execute("mkdir -p ~/.ssh")
            comm.execute("chmod 0700 ~/.ssh")
            comm.execute("printf '#{contents}\\n' >> ~/.ssh/authorized_keys")
            comm.execute("chmod 0600 ~/.ssh/authorized_keys")
          end
        end
      end
    end
  end
end
