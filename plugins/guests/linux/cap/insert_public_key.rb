module VagrantPlugins
  module GuestLinux
    module Cap
      class InsertPublicKey
        def self.insert_public_key(machine, contents)
          machine.communicate.tap do |comm|
            comm.execute("echo #{contents} > /tmp/key.pub")
            comm.execute("mkdir -p ~/.ssh")
            comm.execute("chmod 0700 ~/.ssh")
            comm.execute("cat /tmp/key.pub >> ~/.ssh/authorized_keys")
            comm.execute("chmod 0600 ~/.ssh/authorized_keys")
          end
        end
      end
    end
  end
end
