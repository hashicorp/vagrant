# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module GuestCentos
    module Cap
      class Flavor
        def self.flavor(machine)
          # Pick up version info from `/etc/os-release`. This file started to exist
          # in CentOS 7. For versions before that (i.e. CentOS 6) just plain `:centos`
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
            return :centos
          else
            return "centos_#{version}".to_sym
          end
        end
      end
    end
  end
end
