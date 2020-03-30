require "log4r"

module VagrantPlugins
  module HyperV
    module Cap
      module ValidateDiskExt
        LOGGER = Log4r::Logger.new("vagrant::plugins::hyperv::validate_disk_ext")

        # The default set of disk formats that VirtualBox supports
        DEFAULT_DISK_EXT = ["vdi", "vmdk", "vhd"].map(&:freeze).freeze

        # @param [Vagrant::Machine] machine
        # @param [String] disk_ext
        # @return [Bool]
        def self.validate_disk_ext(machine, disk_ext)
          DEFAULT_DISK_EXT.include?(disk_ext)
        end

        # @param [Vagrant::Machine] machine
        # @return [Array]
        def self.get_default_disk_ext(machine)
          DEFAULT_DISK_EXT
        end
      end
    end
  end
end
