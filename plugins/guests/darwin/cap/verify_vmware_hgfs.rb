module VagrantPlugins
  module GuestDarwin
    module Cap
      class VerifyVmwareHgfs
        def self.verify_vmware_hgfs(machine)
          kext_bundle_id = "com.vmware.kext.vmhgfs"
          machine.communicate.test("kextstat -b #{kext_bundle_id} -l | grep #{kext_bundle_id}")
        end
      end
    end
  end
end
