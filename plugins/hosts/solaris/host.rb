require 'log4r'

require "vagrant"
require 'vagrant/util/platform'

module VagrantPlugins
  module HostSolaris
    class Host < Vagrant.plugin("2", :host)
      include Vagrant::Util

      def self.match?
        Vagrant::Util::Platform.solaris?
      end

      def self.precedence
        5
      end

      def initialize(*args)
        super

        @logger = Log4r::Logger.new("vagrant::hosts::solaris")
      end

      def nfs?
        true
      end

      def nfs_export(id, ip, folders)
        return if !File.exist?("/etc/dfs/sharetab")

        @ui.info I18n.t("vagrant.hosts.solaris.nfs_export")

        # Clean up
        File.read("/etc/dfs/sharetab").lines.each do |line|
          path, resource, fstype, option, description, shid = line.split(/\s/)
          if description == "VAGRANT:"
            if id == shid
              system("unshare #{path}")
              break
            end
          end
        end

        # Start share
        folders.each do |folder|
          system("share -F nfs -o rw=#{ip} -d 'VAGRANT: #{id}' #{folder}")
        end
      end

      def nfs_prune(valid_ids)
        return if !File.exist?("/etc/dfs/sharetab")

        @logger.info("Pruning invalid NFS entries...")

        output = false

        File.read("/etc/dfs/sharetab").lines.each do |line|
          path, resource, fstype, option, description, shid = line.split(/\s/)
          if description == "VAGRANT:"
            if valid_ids.include?(shid)
              @logger.debug("Valid ID: #{shid}")
            else
              if !output
                # We want to warn the user but we only want to output once
                @ui.info I18n.t("vagrant.hosts.solaris.nfs_prune")
                output = true
              end
              @logger.info("Invalid ID, pruning: #{shid}")
              system("unshare #{path}")
            end
          end
        end
      end

    end
  end
end
