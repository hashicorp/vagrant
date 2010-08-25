module Vagrant
  module Command
    class StatusCommand < Base
      desc "Shows the status of the current Vagrant environment."
      argument :name, :type => :string, :optional => true
      register "status"

      def route
        require_environment
        show_multivm if target_vms.length > 1
        show_single(target_vms.first)
      end

      protected

      def show_multivm
        puts Util::Translator.t(:status_listing)
        puts ""

        env.vms.each do |name, vm|
          state = vm.created? ? vm.vm.state : "not created"
          puts "#{name.to_s.ljust(30)}#{state}"
        end
      end

      def show_single(vm)
        string_key = nil

        if !vm.created?
          string_key = :status_not_created
        else
          additional_key = nil
          if vm.vm.running?
            additional_key = :status_created_running
          elsif vm.vm.saved?
            additional_key = :status_created_saved
          elsif vm.vm.powered_off?
            additional_key = :status_created_powered_off
          end

          string_key = [:status_created, {
            :vm_state => vm.vm.state,
            :additional_message => additional_key ? Util::Translator.t(additional_key) : ""
          }]
        end

        puts Util::Translator.t(*string_key)
      end
    end
  end
end
