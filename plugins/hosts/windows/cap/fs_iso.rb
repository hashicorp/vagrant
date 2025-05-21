# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

require "pathname"
require "vagrant/util/caps"

module VagrantPlugins
  module HostWindows
    module Cap
      class FsISO
        extend Vagrant::Util::Caps::BuildISO

        @@logger = Log4r::Logger.new("vagrant::host::windows::fs_iso")

        BUILD_ISO_CMD = "oscdimg.exe".freeze
        DEPLOYMENT_KIT_PATHS = [
          "C:/Program Files (x86)/Windows Kits/10/Assessment and Deployment Kit/Deployment Tools".freeze,
        ].freeze

        # Check that the host has the ability to generate ISOs
        #
        # @param [Vagrant::Environment] env
        # @return [Boolean]
        def self.isofs_available(env)
          begin
            oscdimg_path
            true
          rescue Vagrant::Errors::OscdimgCommandMissingError
            false
          end
        end

        # Generate an ISO file of the given source directory
        #
        # @param [Vagrant::Environment] env
        # @param [String] source_directory Contents of ISO
        # @param [Map] extra arguments to pass to the iso building command
        #              :file_destination (string) location to store ISO
        #              :volume_id (String) to set the volume name
        # @return [Pathname] ISO location
        # @note If file_destination exists, source_directory will be checked
        #       for recent modifications and a new ISO will be generated if requried.
        def self.create_iso(env, source_directory, extra_opts={})
          source_directory = Pathname.new(source_directory)
          file_destination = self.ensure_output_iso(extra_opts[:file_destination])

          iso_command = [oscdimg_path, "-j1", "-o", "-m"]
          iso_command << "-l#{extra_opts[:volume_id]}" if extra_opts[:volume_id]
          iso_command << source_directory.to_s
          iso_command << file_destination.to_s
          self.build_iso(iso_command, source_directory, file_destination)

          @@logger.info("ISO available at #{file_destination}")
          file_destination
        end

        # @return [String] oscdimg executable
        def self.oscdimg_path
          return BUILD_ISO_CMD if Vagrant::Util::Which.which(BUILD_ISO_CMD)
          @@logger.debug("#{BUILD_ISO_CMD} not found on PATH")
          DEPLOYMENT_KIT_PATHS.each do |base|
            path = File.join(base, Vagrant::Util::Platform.architecture,
              "Oscdimg", BUILD_ISO_CMD)
            @@logger.debug("#{BUILD_ISO_CMD} check at #{path}")
            return path if File.executable?(path)
          end

          raise Vagrant::Errors::OscdimgCommandMissingError
        end
      end
    end
  end
end
