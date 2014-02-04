require "vagrant/util/shell_quote"

module VagrantPlugins
  module GuestFreeBSD
    module Cap
      class InsertPublicKey
        def self.insert_public_key(machine, contents)
          contents = Vagrant::Util::ShellQuote.escape(contents, "'")
          contents = contents.gsub("\n", "\\n")

          machine.communicate.tap do |comm|
            comm.execute("mkdir -p ~/.ssh", shell: "sh")
            comm.execute("chmod 0700 ~/.ssh", shell: "sh")
            comm.execute("printf '#{contents}' >> ~/.ssh/authorized_keys", shell: "sh")
            comm.execute("chmod 0600 ~/.ssh/authorized_keys", shell: "sh")
          end
        end
      end
    end
  end
end
