module Vagrant
  module Command
    class StatusCommand < Base
      desc "Shows the status of the current Vagrant environment."
      argument :name, :type => :string, :optional => true
      register "status"

      def route
        require_environment

        state = nil
        results = env.vms.collect do |name, vm|
          state ||= vm.created? ? vm.vm.state.to_s : "not_created"
          "#{name.to_s.ljust(25)}#{state.gsub("_", " ")}"
        end

        state = env.vms.length == 1 ? state : "listing"

        env.ui.info("vagrant.commands.status.output",
                    :states => results.join("\n"),
                    :message => I18n.t("vagrant.commands.status.#{state}"),
                    :_prefix => false)
      end
    end
  end
end
