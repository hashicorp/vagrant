require 'sys/proctable'

module Acceptance
  module VirtualBox
    extend self

    # This method will wait for the "VBoxSVC" process to end. This will
    # block during that time period. The reason for this is because only
    # one "VBoxSVC" can run per user and manages all state within VirtualBox.
    # Before you can run VirtualBox with a custom home directory, you must
    # wait for this VBoxSVC process to die.
    def wait_for_vboxsvc
      time_passed = 0
      while find_vboxsvc
        if time_passed > 5
          raise Exception, "VBoxSVC process is not going away."
        end

        sleep 1
        time_passed += 1
      end
    end

    # This method finds the VBoxSVC process and returns information about it.
    # This will return "nil" if VBoxSVC is not found.
    def find_vboxsvc
      Sys::ProcTable.ps do |process|
        if process.comm == "VBoxSVC"
          return process
        end
      end

      nil
    end
  end
end
