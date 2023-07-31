# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module GuestRedHat
    module Cap
      class Flavor
        def self.flavor(machine)
          # Pick up version info from `/etc/os-release`. This file started to exist
          # in RHEL 7. For versions before that (i.e. RHEL 6) just plain `:rhel`
          # should do.
          version = nil
          if machine.communicate.test("test -f /etc/os-release")
            begin
              machine.communicate.execute("source /etc/os-release && printf $VERSION_ID") do |type, data|
                if type == :stdout
                  version = data.split(".").first.to_i
                end
              end
            rescue
            end
          end
          if version.nil? || version < 1
            return :rhel
          else
            return "rhel_#{version}".to_sym
          end
        end
      end
    end
  end
end
