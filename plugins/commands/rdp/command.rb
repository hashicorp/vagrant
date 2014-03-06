module VagrantPlugins
  module CommandRdp
    class Command < Vagrant.plugin("2", :command)
      def self.synopsis
        "opens a RDP session for a vagrant machine"
      end

      def execute
        with_target_vms do |vm|
          vm.action(:rdp)
        end
        # Success, exit status 0
        0
      end
    end
  end
end
