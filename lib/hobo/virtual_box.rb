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