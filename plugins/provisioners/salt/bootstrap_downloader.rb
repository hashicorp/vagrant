# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

Vagrant.require 'open-uri'
Vagrant.require 'digest'

require_relative "./errors"

module VagrantPlugins
  module Salt
    class BootstrapDownloader
      WINDOWS_URL = "﻿https://github.com/saltstack/salt-bootstrap/releases/latest/download/bootstrap-salt.ps1"
      URL = "https://github.com/saltstack/salt-bootstrap/releases/latest/download/bootstrap-salt.sh"
      SHA256_SUFFIX = ".sha256"

      def initialize(guest)
        @guest = guest
        @logger  = Log4r::Logger.new("vagrant::salt::bootstrap_downloader")
      end

      def source_url 
        @guest == :windows ? WINDOWS_URL : URL
      end

      def get_bootstrap_script
        @logger.debug "Downloading bootstrap script from #{source_url}"
        script_file = download(source_url)

        verify_sha256(script_file)

        @logger.info "Downloaded and verified salt-bootstrap script"
        script_file
      end

      def verify_sha256(script)
        @logger.debug "Downloading sha256 file from #{source_url}#{SHA256_SUFFIX}"
        sha256_file = download("#{source_url}#{SHA256_SUFFIX}")
        sha256 = extract_sha256(sha256_file.read)
        sha256_file.close

        @logger.debug "Computing sha256 value from script file"
        computed_sha256 = Digest::SHA256.hexdigest(script.read)
        script.rewind

        @logger.debug "Comparing sha256 values"
        if computed_sha256 != sha256
          @logger.debug "Mismatched sha256, expected #{sha256} but computed #{computed_sha256}"
          raise Salt::Errors::InvalidShasumError, source: source_url, expected_sha: sha256, computed_sha: computed_sha256
        end
        @logger.debug "Sha256 values match"
      end

      def extract_sha256(text)
        text.scan(/\b([a-f0-9]{64})\b/).last.first
      end

      def download(url)
        URI(url).open
      end
    end
  end
end
