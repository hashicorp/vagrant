module Vagrant
  module Command
    class StatusCommand < Base
      argument :name, :type => :string, :optional => true
      register "status", "Shows the status of the current Vagrant environment."

      def route
        state = nil
        results = env.vms.collect do |name, vm|
          state ||= vm.created? ? vm.vm.state.to_s : "not_created"
          "#{name.to_s.ljust(25)}#{state.gsub("_", " ")}"
        end

        state = env.vms.length == 1 ? state : "listing"

        env.ui.info(I18n.t("vagrant.commands.status.output",
                    :states => results.join("\n"),
                    :message => I18n.t("vagrant.commands.status.#{state}")),
                    :prefix => false)
      end
    end
  end
end
