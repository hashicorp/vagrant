class VirtualBox
  class <<self
    def create(name, options = {})
      # To create the VM, we simply import the base OVF which takes care
      # of matching up the hardware and setting up the configuration.
      command("import #{File.expand_path("~/.hobo/base/base.ovf")} --vsys 0 --vmname #{name}")
      
      # We must manually modify the mac address to match the base VM
      # so that eth0 will still work
      command("modifyvm #{name} --macaddress1 08002771F257")
    end
    
    def destroy(name)
      # We must first get the vm info to parse which disk images this
      # vm is using, since we'll have to remove those as well.
      vminfo = parse_kv_pairs(command("showvminfo #{name} --machinereadable"))
      
      # Detach mediums associated with VM so we can delete
      # TODO: Make this use the vminfo returned to be flexible enough to destroy
      # all mediums for any machine
      command("storageattach #{name} --storagectl \"IDE Controller\" --port 0 --device 0 --medium none")
      command("storageattach #{name} --storagectl \"IDE Controller\" --port 1 --device 0 --medium none")
      command("storageattach #{name} --storagectl \"Floppy Controller\" --port 0 --device 0 --medium none")
      
      # Remove the disk associated with the VM
      command("closemedium disk #{vminfo["IDE Controller-0-0"]} --delete")

      # Remove and delete the VM (unregister)
      command("unregistervm #{name} --delete")
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
    
    # Parses the key value pairs from the VBoxManage key=value pair
    # format and returns as a Ruby Hash
    def parse_kv_pairs(raw)
      parsed = {}
      
      raw.lines.each do |line|
        # Some lines aren't configuration, we just ignore them
        next unless line =~ /^"?(.+?)"?="?(.+?)"?$/
        
        parsed[$1] = $2.strip
      end
      
      parsed
    end
  end
end