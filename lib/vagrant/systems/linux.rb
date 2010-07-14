module Vagrant
  module Systems
    # A general Vagrant system implementation for "linux." In general,
    # any linux-based OS will work fine with this system, although its
    # not tested exhaustively. BSD or other based systems may work as
    # well, but that hasn't been tested at all.
    #
    # At any rate, this system implementation should server as an
    # example of how to implement any custom systems necessary.
    class Linux < Base
      # A custom config class which will be made accessible via `config.linux`
      # This is not necessary for all system implementers, of course. However,
      # generally, Vagrant tries to make almost every aspect of its execution
      # configurable, and this assists that goal.
      class LinuxConfig < Vagrant::Config::Base
        attr_accessor :halt_timeout
        attr_accessor :halt_check_interval

        def initialize
          @halt_timeout = 30
          @halt_check_interval = 1
        end
      end

      # Register config class
      Config.configures :linux, LinuxConfig

      #-------------------------------------------------------------------
      # Overridden methods
      #-------------------------------------------------------------------
      def halt
        logger.info "Attempting graceful shutdown of linux..."
        vm.ssh.execute do |ssh|
          ssh.exec!("sudo halt")
        end

        # Wait until the VM's state is actually powered off. If this doesn't
        # occur within a reasonable amount of time (15 seconds by default),
        # then simply return and allow Vagrant to kill the machine.
        count = 0
        while vm.vm.state != :powered_off
          count += 1

          return if count >= vm.env.config.linux.halt_timeout
          sleep vm.env.config.linux.halt_check_interval
        end
      end

      def mount_shared_folder(ssh, name, guestpath)
        ssh.exec!("sudo mkdir -p #{guestpath}")
        mount_folder(ssh, name, guestpath)
        ssh.exec!("sudo chown #{config.ssh.username} #{guestpath}")
      end

      def mount_nfs(ip, folders)
        # TODO: Maybe check for nfs support on the guest, since its often
        # not installed by default
        folders.each do |name, opts|
          vm.ssh.execute do |ssh|
            ssh.exec!("sudo mkdir -p #{opts[:guestpath]}")
            ssh.exec!("sudo mount #{ip}:#{opts[:hostpath]} #{opts[:guestpath]}")
          end
        end
      end

      def prepare_unison(ssh)
        ssh.exec!("which unison", :error_key => :unison_not_found)

        logger.info "Preparing system for unison sync..."
        vm.ssh.upload!(StringIO.new(TemplateRenderer.render('/unison/script')), config.unison.script)
        ssh.exec!("sudo chmod +x #{config.unison.script}")
        ssh.exec!("sudo rm #{config.unison.crontab_entry_file}", :error_check => false)
      end

      def create_unison(ssh, opts)
        sanitized_string = opts[:original][:guestpath].gsub(/[^a-zA-Z0-9_-]/, '-')
        crontab_entry = TemplateRenderer.render('/unison/crontab_entry',
                                                :from => opts[:guestpath],
                                                :to => opts[:original][:guestpath],
                                                :options => config.unison.options,
                                                :script => config.unison.script,
                                                :log_file => (config.unison.log_file % sanitized_string))

        ssh.exec!("sudo rm -rf ~/.unison")
        ssh.exec!("sudo rm -rf #{opts[:original][:guestpath]}")
        ssh.exec!("sudo echo \"#{crontab_entry}\" >> #{config.unison.crontab_entry_file}")
        ssh.exec!("crontab #{config.unison.crontab_entry_file}")
      end

      def prepare_host_only_network
        # Remove any previous host only network additions to the
        # interface file.
        vm.ssh.execute do |ssh|
          # Verify debian/ubuntu
          ssh.exec!("cat /etc/debian_version", :error_key => :network_not_debian)

          # Clear out any previous entries
          ssh.exec!("sudo sed -e '/^#VAGRANT-BEGIN/,/^#VAGRANT-END/ d' /etc/network/interfaces > /tmp/vagrant-network-interfaces")
          ssh.exec!("sudo su -c 'cat /tmp/vagrant-network-interfaces > /etc/network/interfaces'")
        end
      end

      def enable_host_only_network(net_options)
        entry = TemplateRenderer.render('network_entry', :net_options => net_options)
        vm.ssh.upload!(StringIO.new(entry), "/tmp/vagrant-network-entry")

        vm.ssh.execute do |ssh|
          ssh.exec!("sudo su -c 'cat /tmp/vagrant-network-entry >> /etc/network/interfaces'")
          ssh.exec!("sudo /etc/init.d/networking restart")
        end
      end

      #-------------------------------------------------------------------
      # "Private" methods which assist above methods
      #-------------------------------------------------------------------
      def mount_folder(ssh, name, guestpath, sleeptime=5)
        # Determine the permission string to attach to the mount command
        perms = []
        perms << "uid=#{vm.env.config.vm.shared_folder_uid}"
        perms << "gid=#{vm.env.config.vm.shared_folder_gid}"
        perms = " -o #{perms.join(",")}" if !perms.empty?

        attempts = 0
        while true
          result = ssh.exec!("sudo mount -t vboxsf#{perms} #{name} #{guestpath}") do |ch, type, data|
            # net/ssh returns the value in ch[:result] (based on looking at source)
            ch[:result] = !!(type == :stderr && data =~ /No such device/i)
          end

          break unless result

          attempts += 1
          raise Action::ActionException.new(:vm_mount_fail) if attempts >= 10
          sleep sleeptime
        end
      end

      def config
        vm.env.config
      end
    end
  end
end
