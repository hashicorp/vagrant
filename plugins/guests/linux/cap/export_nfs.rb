require "vagrant/util/retryable"
require 'vagrant/util/platform'

module VagrantPlugins
  module GuestLinux
    module Cap
      class ExportNFS
        extend Vagrant::Util::Retryable
        include Vagrant::Util

        def self.export_nfs_capable(machine)
          me = self.new(machine)
          return me.nfs_capable?
        end

        def self.export_nfs_folders(machine, ip, folders)
          me = self.new(machine, ip, folders)

          me.nfs_opts_setup()
          output = TemplateRenderer.render('nfs/guest_exports_linux',
                                           :uuid => machine.id,
                                           :ips => [ip],
                                           :folders => folders,
                                           :user => Process.uid)

          machine.ui.info I18n.t("vagrant.hosts.linux.nfs_export")
          sleep 0.5

          me.nfs_cleanup()

          output.split("\n").each do |line|
            machine.communicate.sudo(%Q[echo '#{line}' >> /etc/exports])
          end

          me.restart_nfs()
        end

        def initialize(machine, ip = [], folders = [])
          @machine = machine
          @ip = ip
          @folders = folders

          @folder_test_command  = "test -d"
          @nfs_test_command  = "test -e /etc/exports"
          @nfs_apply_command = "/usr/sbin/exportfs -r"
          @nfs_check_command = "/etc/init.d/nfs-kernel-server status"
          @nfs_start_command = "/etc/init.d/nfs-kernel-server start"
        end

        def nfs_running?
          @machine.communicate.test("#{@nfs_check_command}")
        end

        def nfs_capable?
          @machine.communicate.test("#{@nfs_test_command}")
        end

        # TODO - DRY this ripped completely from plugins/hosts/linux/host.rb
        def nfs_opts_setup()
          @folders.each do |k, opts|
            if !opts[:linux__nfs_options]
              opts[:linux__nfs_options] ||= ["rw", "no_subtree_check", "all_squash", "insecure"]
            end

            # Only automatically set anonuid/anongid if they weren't
            # explicitly set by the user.
            hasgid = false
            hasuid = false
            opts[:linux__nfs_options].each do |opt|
              hasgid = !!(opt =~ /^anongid=/) if !hasgid
              hasuid = !!(opt =~ /^anonuid=/) if !hasuid
            end

            opts[:linux__nfs_options] << "anonuid=#{opts[:map_uid]}" if !hasuid
            opts[:linux__nfs_options] << "anongid=#{opts[:map_gid]}" if !hasgid
            opts[:linux__nfs_options] << "fsid=#{opts[:uuid]}"

            # Expand the guest path so we can handle things like "~/vagrant"
            expanded_guest_path = @machine.guest.capability(
              :shell_expand_guest_path, opts[:guestpath])

            # Do the actual creating and mounting
            @machine.communicate.sudo("mkdir -p #{expanded_guest_path}")
          end
        end

        def nfs_cleanup()
          return if !nfs_capable?

          id = @machine.id
          user = Process.uid

          # Use sed to just strip out the block of code which was inserted
          # by Vagrant
          @machine.communicate.sudo("sed -r -e '/^# VAGRANT-BEGIN:( #{user})? #{id}/,/^# VAGRANT-END:( #{user})? #{id}/ d' -ibak /etc/exports")
        end

        def restart_nfs()
          if nfs_running?
            @machine.communicate.sudo("#{@nfs_apply_command}")
          else
            @machine.communicate.sudo("#{@nfs_start_command}")
          end
        end

      end
    end
  end
end
