module Vagrant
  module Command
    class StatusCommand < NamedBase
      register "status", "Shows the status of the current Vagrant environment."

      def route
        state = nil
        results = target_vms.collect do |vm|
          state ||= vm.created? ? vm.vm.state.to_s : "not_created"
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
