# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module HostDarwin
    module Cap
      class Version
        def self.version(env)
          r = Vagrant::Util::Subprocess.execute("sw_vers", "-productVersion")
          if r.exit_code != 0
            raise Vagrant::Errors::DarwinVersionFailed,
              version: r.stdout,
              error: r.stderr
          end
          begin
            Gem::Version.new(r.stdout)
          rescue => err
            raise Vagrant::Errors::DarwinVersionFailed,
              version: r.stdout,
              error: err.message
          end
        end
      end
    end
  end
end
