# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

Vagrant.require "pathname"
Vagrant.require "tempfile"

Vagrant.require "vagrant/util/downloader"
Vagrant.require "vagrant/util/file_checksum"
Vagrant.require "vagrant/util/powershell"
Vagrant.require "vagrant/util/subprocess"

module VagrantPlugins
  module HostWindows
    module Cap
      class ConfiguredIPAddresses

        def self.configured_ip_addresses(env)
          script_path = File.expand_path("../../scripts/host_info.ps1", __FILE__)
          r = Vagrant::Util::PowerShell.execute(script_path)
          if r.exit_code != 0
            raise Vagrant::Errors::PowerShellError,
              script: script_path,
              stderr: r.stderr
          end

          res = JSON.parse(r.stdout)["ip_addresses"]
          Array(res)
        end
      end
    end
  end
end
