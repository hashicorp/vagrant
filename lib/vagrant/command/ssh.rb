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
          ssh_vm.env.ui.info I18n.t("vagrant.commands.ssh.command", :command => options[:command])
          ssh.exec!(options[:command]) do |channel, type, data|
            ssh_vm.env.ui.info "#{data}"
          end
        end
      end

      def ssh_connect
        raise Errors::VMNotCreatedError if !ssh_vm.created?
        raise Errors::VMNotRunningError if !ssh_vm.vm.running?
        ssh_vm.ssh.connect
      end

      def ssh_vm
        @ssh_vm ||= begin
          vm = self.name.nil? && env.multivm? ? env.primary_vm : nil
          raise Errors::MultiVMTargetRequired, :command => "ssh" if !vm && target_vms.length > 1
          vm = target_vms.first if !vm
          vm
        end
      end
    end
  end
end
