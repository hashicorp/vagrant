module Vagrant
  module Command
    class StatusCommand < NamedBase
      register "status", "Shows the status of the current Vagrant environment."

      def execute
        state = nil
        results = target_vms.collect do |vm|
          if vm.created?
            if vm.vm.accessible?
              state = vm.vm.state.to_s
            else
              state = "inaccessible"
            end
          else
            state = "not_created"
          end

          vm.ssh.exit_all
          vm.ssh.show_all_connection_output

          "#{vm.name.to_s.ljust(25)}#{state.gsub("_", " ")}"
        end

        state = target_vms.length == 1 ? state : "listing"

        env.ui.info(I18n.t("vagrant.commands.status.output",
                    :states => results.join("\n"),
                    :message => I18n.t("vagrant.commands.status.#{state}")),
                    :prefix => false)
      end
    end
  end
end
