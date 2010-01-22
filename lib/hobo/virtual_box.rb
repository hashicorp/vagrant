class VirtualBox
  class <<self
    def create(name, options = {})      
      modify_options = {
        # Set up base system: memory, cpus, etc.
        "memory"          => options[:memory] || "360",
        "vram"            => options[:vram] || "12",
        "ostype"          => "Ubuntu",
        "acpi"            => "on",
        "ioapic"          => "off",
        "cpus"            => "1",
        "pae"             => "on",
        "hwvirtex"        => "on",
        "hwvirtexexcl"    => "off",
        "nestedpaging"    => "off",
        "vtxvpid"         => "off",
        "accelerate3d"    => "off",
        "biosbootmenu"    => "messageandmenu",
        "boot1"           => "disk",
        "boot2"           => "dvd",
        "boot3"           => "none",
        "boot4"           => "none",
        "firmware"        => "bios",
        # Networking
        "nic1"            => "bridged",
        "nictype1"        => "Am79C973",
        "cableconnected1" => "on",
        "nictrace1"       => "off",
        "bridgeadapter1"  => "en0: Ethernet",
        # Ports
        "audio"           => "none",
        "clipboard"       => "bidirectional",
        "usb"             => "off",
        "usbehci"         => "off"
      }
      
      # Create the raw machine itself. In this incarnation, nothing
      # is yet configured.
      HOBO_LOGGER.info("Creating VM #{name}...")
      command("createvm --name #{name} --register")
      
      # Modify the VM with the options set
      modify_options.each { |key, value| modify(name, key, value) }
      
      # Clone the hard drive that we'll be using
      # TODO: Change hardcoded paths to use config module when ready
      HOBO_LOGGER.info("Cloning from base disk...")
      clone_disk("/Users/mitchellh/.hobo/disks/base.vmdk", "/Users/mitchellh/.hobo/disks/#{name}.vmdk")
      
      # Attach storage controllers
      HOBO_LOGGER.info("Attaching clone disk to VM...")
      command("storagectl #{name} --name \"IDE Controller\" --add ide --controller PIIX4 --sataportcount 2")
      command("storageattach #{name} --storagectl \"IDE Controller\" --port 0 --device 0 --type hdd --medium \"/Users/mitchellh/.hobo/disks/#{name}.vmdk\"")
    end
    
    def modify(name, key, value)
      # Wrap values with spaces in quotes
      value = "\"#{value}\"" if value =~ /\s/
      
      command("modifyvm #{name} --#{key} #{value}")
    end
    
    def clone_disk(sourcepath, destpath)
      # TODO: Escape filepaths
      command("clonehd #{sourcepath} #{destpath}")
    end
    
    def command(cmd)
      HOBO_LOGGER.debug "Command: #{cmd}"
      result = `VBoxManage #{cmd}`
      
      if $?.to_i >= 1
        HOBO_LOGGER.error "VBoxManage command failed: #{cmd}"
        # TODO: Raise error here that other commands can catch?
        raise Exception.new("Failure: #{result}")
      end
      
      return result
    end
  end
end