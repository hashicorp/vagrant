module Vagrant
  module Command
    class SSHCommand < NamedBase
      class_option :command, :type => :string, :default => false, :aliases => "-c"
      register "ssh", "SSH into the currently running Vagrant environment."

      def execute
        if options[:command]
          ssh_execute
        else
          ssh_connect
        end
      end

      protected

      def ssh_execute
        ssh_vm.ssh.execute do |ssh|
          ssh.exec!(options[:command]) do |channel, type, data|
            if type != :exit_status
              # Print the SSH output as it comes in, but don't prefix it and don't
              # force a new line so that the output is properly preserved
              ssh_vm.env.ui.info(data.to_s, :prefix => false, :new_line => false)
            end
          end
        end
      end

      def ssh_connect
        ssh_vm.ssh.connect
      end

      def ssh_vm
        @ssh_vm ||= begin
          vm = self.name.nil? && env.multivm? ? env.primary_vm : nil
          raise Errors::MultiVMTargetRequired, :command => "ssh" if !vm && target_vms.length > 1
          vm = target_vms.first if !vm

          # Basic checks that are required for proper SSH
          raise Errors::VMNotCreatedError if !vm.created?
          raise Errors::VMInaccessible if !vm.vm.accessible?
          raise Errors::VMNotRunningError if !vm.vm.running?

          vm
        end
      end
    end
  end
end
