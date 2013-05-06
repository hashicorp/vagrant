require 'log4r'

require "vagrant"
require 'vagrant/util/platform'

module VagrantPlugins
  module HostLinux
    # Represents a Linux based host, such as Ubuntu.
    class Host < Vagrant.plugin("2", :host)
      include Vagrant::Util
      include Vagrant::Util::Retryable

      def self.match?
        Vagrant::Util::Platform.linux?
      end

      def self.precedence
        # Set a lower precedence because this is a generic OS. We
        # want specific distros to match first.
        2
      end

      def initialize(*args)
        super

        @logger = Log4r::Logger.new("vagrant::hosts::linux")
        @nfs_server_binary = "/etc/init.d/nfs-kernel-server"
      end

      def nfs?
        retryable(:tries => 10, :on => TypeError) do
          # Check procfs to see if NFSd is a supported filesystem
          system("cat /proc/filesystems | grep nfsd > /dev/null 2>&1")
        end
      end

      def nfs_export(id, ip, folders)
        exports = folders.map do |name, opts| 
          # prepare NFS options
          options = %W(rw no_subtree_check all_squash fsid=#{opts[:uuid]})
          options << "anonuid=#{opts[:map_uid]}" if opts[:map_uid]
          options << "anongid=#{opts[:map_gid]}" if opts[:map_gid]
          
          {
            :ip      => ip,
            :host    => opts[:hostpath],
            :options => options,
          }
        end 

        @ui.info I18n.t("vagrant.hosts.linux.nfs_export")
        sleep 0.5

        exports.each do |export|
          system(%Q[sudo exportfs -o #{export[:options].join(',')} #{export[:ip]}:#{export[:host]}])
        end
      end

      def nfs_prune(valid_ids)
        @logger.info("Pruning invalid NFS entries...")
        output = false

        # remove "-" from machine valid machine id
        valid_ids = valid_ids.map { |id| id.delete('-') }

        current_exports.each do |export|
          if id = export[:options][/fsid=([\w\d]+)?/, 1]
            if valid_ids.include?(id)
              @logger.debug("Valid ID: #{id}")
            else
              if !output
                # We want to warn the user but we only want to output once
                @ui.info I18n.t("vagrant.hosts.linux.nfs_prune")
                output = true
              end

              @logger.info("Invalid ID, pruning: #{id}")
              nfs_cleanup(export[:ip], export[:host])
            end
          end
        end
      end

      protected

      def nfs_cleanup(ip, host)
        system("sudo exportfs -u #{ip}:#{host}")
      end
      
      def current_exports
        exports = `sudo exportfs -v`
        # exportfs output should be properly parsed
        #
        # this is a little bit complicated because folder with long path look like this:
        #   `sudo exportfs -v`
        #   #=> "/very_long_path\n\t\t192.168.122.4(rw,all_squash,no_subtree_check,fsid=68f4ad0105a6a490826e8d8861140d84)"
        #
        # while short paths look like this:
        #   `sudo exportfs -v`
        #   #=> "/short_path      \t192.168.122.153(rw,all_squash,no_subtree_check,fsid=68f4ad0105a6a490826e8d8861140d84)"
        #
        # and we need to properly handle both cases
        exports = exports.split "\n"         # each new line is either folder or ip
        exports.map! { |e| e.split("\t") }   # tab either prepends ip
        exports.flatten!                     # make one-dimensional array
        exports.select! { |e| !e.empty? }    # remove all empty strings (created by old entries)
        exports.map! &:strip                 # make sure there are no leading spaces
        
        Hash[*exports].map do |folder, ip_and_opts|
          # get IP and options froms string like
          # "192.168.122.167(rw,all_squash,no_subtree_check,fsid=7a99ad461317ed7c6514de3ce64db3e5)"
          ip_and_opts = ip_and_opts.match(/^(\d+\.\d+\.\d+\.\d+)\((.+)\)$/)
          
          {
            :host    => folder,
            :ip      => ip_and_opts[1],
            :options => ip_and_opts[2],
          }
        end
      end
    end
  end
end
