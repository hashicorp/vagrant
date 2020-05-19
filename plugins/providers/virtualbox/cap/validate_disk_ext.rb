require "log4r"

module VagrantPlugins
  module ProviderVirtualBox
    module Cap
      module ValidateDiskExt
        LOGGER = Log4r::Logger.new("vagrant::plugins::virtualbox::validate_disk_ext")

        # The default set of disk formats that VirtualBox supports
        DEFAULT_DISK_EXT_LIST = ["vdi", "vmdk", "vhd"].map(&:freeze).freeze
        DEFAULT_DISK_EXT = "vdi".freeze

        # @param [Vagrant::Machine] machine
        # @param [String] disk_ext
        # @return [Bool]
        def self.validate_disk_ext(machine, disk_ext)
          DEFAULT_DISK_EXT_LIST.include?(disk_ext)
        end

        # @param [Vagrant::Machine] machine
        # @return [Array]
        def self.default_disk_exts(machine)
          DEFAULT_DISK_EXT_LIST
        end

        # @param [Vagrant::Machine] machine
        # @return [String]
        def self.set_default_disk_ext(machine)
          DEFAULT_DISK_EXT
        end
      end
    end
  end
end
