# Copyright IBM Corp. 2010, 2025
# SPDX-License-Identifier: BUSL-1.1

module VagrantPlugins
  module GuestSUSE
    class Guest < Vagrant.plugin("2", :guest)
      def detect?(machine)
        machine.communicate.test("test -f /etc/SuSE-release || grep -q SUSE /etc/os-release")
      end

      # Detect the SUSE version from /etc/os-release
      # @return [String, nil] Version string (e.g., "15.6", "16.0") or nil if not detected
      def self.detect_version(machine)
        version = nil
        if machine.communicate.test("test -f /etc/os-release")
          machine.communicate.execute("source /etc/os-release && printf $VERSION_ID") do |type, data|
            if type == :stdout
              version = data.strip
            end
          end
        end
        version
      end

      # Check if the system is OpenSUSE Leap 16 or newer
      # @return [Boolean] True if Leap 16+ or newer
      def self.leap_16_or_newer?(machine)
        version = detect_version(machine)
        return false unless version
        # Parse version like "15.5", "16.0", etc.
        major_version = version.split(".").first.to_i
        major_version >= 16
      end

      # Check if NetworkManager is available and active on the system
      # @return [Boolean] True if NetworkManager is available
      def self.network_manager_available?(machine)
        comm = machine.communicate
        nmcli_installed = comm.test("command -v nmcli", sudo: true)
        nm_active = comm.test("systemctl -q is-active NetworkManager.service", sudo: true)
        nmcli_installed && nm_active
      end
    end
  end
end
