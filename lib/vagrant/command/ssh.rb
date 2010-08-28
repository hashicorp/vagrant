module Vagrant
  module Command
    class SSHCommand < NamedBase
      desc "SSH into the currently running Vagrant environment."
      class_option :execute, :type => :string, :default => false, :aliases => "-e"
      register "ssh"

      def execute
        if options[:execute]
          ssh_execute
        else
          ssh_connect
        end
      end

      protected

      def ssh_execute
        ssh_vm.ssh.execute do |ssh|
          ssh_vm.env.ui.info "vagrant.commands.ssh.execute", :command => options[:execute]
          ssh.exec!(options[:execute]) do |channel, type, data|
            ssh_vm.env.ui.info "#{data}"
          end
        end
      end

      def ssh_connect
        raise VMNotCreatedError.new if !ssh_vm.created?
        ssh_vm.ssh.connect
      end

      def ssh_vm
        @ssh_vm ||= begin
          vm = self.name.nil? && env.multivm? ? env.primary_vm : nil
          raise MultiVMTargetRequired.new(:command => "ssh") if !vm && target_vms.length > 1
          vm = target_vms.first if !vm
          vm
        end
      end
    end
  end
end
