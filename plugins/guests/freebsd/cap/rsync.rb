module VagrantPlugins
  module GuestFreeBSD
    module Cap
      class RSync
        def self.rsync_install(machine)
          version = nil
          machine.communicate.execute("uname -r") do |type, result|
            version = result.split('.')[0].to_i if type == :stdout
          end

          pkg_cmd = "pkg_add -r"
          if version && version >= 10
            pkg_cmd = "pkg install -y"
          end

          machine.communicate.sudo("#{pkg_cmd} rsync")
        end

        def self.rsync_installed(machine)
          machine.communicate.test("which rsync")
        end

        def self.rsync_command(machine)
          "sudo rsync"
        end

        def self.rsync_pre(machine, opts)
          machine.communicate.tap do |comm|
            comm.sudo("mkdir -p '#{opts[:guestpath]}'")
          end
        end

        def self.rsync_post(machine, opts)
          if opts.key?(:chown) && !opts[:chown]
            return
          end

          machine.communicate.sudo(
            "find '#{opts[:guestpath]}' '(' ! -user #{opts[:owner]} -or ! -group #{opts[:group]} ')' -print0 | " +
            "xargs -0 -r chown #{opts[:owner]}:#{opts[:group]}")
        end
      end
    end
  end
end
