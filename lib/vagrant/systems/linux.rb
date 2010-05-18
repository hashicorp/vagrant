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
          @halt_timeout = 15
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
        chown(ssh, guestpath)
      end

      def create_rsync(ssh, opts)
        crontab_entry = render_crontab_entry(opts.merge(:rsyncopts => config.vm.rsync_opts,
                                                        :scriptname => config.vm.rsync_script))

        ssh.exec!("sudo mkdir -p #{opts[:rsyncpath]}")
        ssh.exec!("sudo chmod +x #{config.vm.rsync_script}")
        ssh.exec!("sudo echo \"#{crontab_entry}\" >> #{config.vm.rsync_crontab_entry_file}")
        ssh.exec!("crontab #{config.vm.rsync_crontab_entry_file}")
        chown(ssh, opts[:rsyncpath])
      end

      def prepare_rsync(ssh)
        logger.info "Preparing system for rsync..."
        vm.env.ssh.upload!(StringIO.new(render_rsync), config.vm.rsync_script)
        ssh.exec!('sudo rm #{config.vm.rsync_crontab_entry_file}')
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
          raise Actions::ActionException.new(:vm_mount_fail) if attempts >= 10
          sleep sleeptime
        end
      end

      def chown(ssh, dir)
        ssh.exec!("sudo chown #{config.ssh.username} #{dir}")
      end

      def config
        vm.env.config
      end

      def render_rsync
        TemplateRenderer.render('rsync')
      end

      def render_crontab_entry(opts)
        TemplateRenderer.render('crontab-entry', opts)
      end
    end
  end
end
