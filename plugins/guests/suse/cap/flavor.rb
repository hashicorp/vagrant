# Copyright IBM Corp. 2010, 2025
# SPDX-License-Identifier: BUSL-1.1

module VagrantPlugins
  module GuestSUSE
    module Cap
      class Flavor
        # Detect the flavor of SUSE for version-specific capabilities
        # @return [Symbol] Flavor symbol (:leap_16_plus, :leap_legacy, :suse)
        def self.flavor(machine)
          version = VagrantPlugins::GuestSUSE::Guest.detect_version(machine)
          if version
            major_version = version.split(".").first.to_i
            if major_version >= 16
              return :leap_16_plus
            else
              return :leap_legacy
            end
          end
          :suse
        end
      end
    end
  end
end