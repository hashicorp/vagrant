# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

Vagrant.require "pathname"

module VagrantPlugins
  module FTPPush
    class Adapter
      attr_reader :host
      attr_reader :port
      attr_reader :username
      attr_reader :password
      attr_reader :options
      attr_reader :server

      def initialize(host, username, password, options = {})
        @host, @port = parse_host(host)
        @username = username
        @password = password
        @options  = options
        @server   = nil
      end

      # Parse the host into it's url and port parts.
      # @return [Array]
      def parse_host(host)
        if host.include?(":")
          split = host.split(":", 2)
          [split[0], split[1].to_i]
        else
          [host, default_port]
        end
      end

      def default_port
        raise NotImplementedError
      end

      def connect(&block)
        raise NotImplementedError
      end

      def upload(local, remote)
        raise NotImplementedError
      end
    end

    #
    # The FTP Adapter
    #
    class FTPAdapter < Adapter
      def initialize(*)
        Vagrant.require "net/ftp"
        super
      end

      def default_port
        21
      end

      def connect(&block)
        @server = Net::FTP.new
        @server.passive = options.fetch(:passive, true)
        @server.connect(host, port)
        @server.login(username, password)

        begin
          yield self
        ensure
          @server.close
        end
      end

      def upload(local, remote)
        parent   = File.dirname(remote)
        fullpath = Pathname.new(File.expand_path(parent, pwd))

        # Create the parent directories if they does not exist (naive mkdir -p)
        fullpath.descend do |path|
          if !directory_exists?(path.to_s)
            @server.mkdir(path.to_s)
          end
        end

        # Upload the file
        @server.putbinaryfile(local, remote)
      end

      def directory_exists?(path)
        begin
          @server.chdir(path)
          return true
        rescue Net::FTPPermError
          return false
        end
      end

      private

      def pwd
        @pwd ||= @server.pwd
      end
    end

    #
    # The SFTP Adapter
    #
    class SFTPAdapter < Adapter
      def initialize(*)
        Vagrant.require "net/sftp"
        super
        @dirs = {}
      end

      def default_port
        22
      end

      def connect(&block)
        Net::SFTP.start(@host, @username, password: @password, port: @port) do |server|
          @server = server
          yield self
        end
      end

      def upload(local, remote)
        dir = File.dirname(remote)

        fullpath = Pathname.new(dir)
        fullpath.descend do |path|
          if @dirs[path.to_s].nil?
            begin
              @server.mkdir!(path.to_s)

              # Cache visited directories in a list to avoid duplicate requests
              @dirs[path.to_s] = true
            rescue Net::SFTP::StatusException => e
              # Directory exists, skip...
            end
          end
        end

        @server.upload!(local, remote)
      end
    end
  end
end
