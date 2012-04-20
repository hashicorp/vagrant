require 'optparse'

module VagrantPlugins
  module CommandStatus
    class Command < Vagrant::Command::Base
      def execute
        options = {}

        opts = OptionParser.new do |opts|
          opts.banner = "Usage: vagrant status [vm-name]"
        end

        # Parse the options
        argv = parse_options(opts)
        return if !argv

        state = nil
        results = []
        with_target_vms(argv) do |vm|
          state = vm.state.to_s if !state
          results << "#{vm.name.to_s.ljust(25)}#{vm.state.to_s.gsub("_", " ")}"
        end

        state = results.length == 1 ? state : "listing"

        @env.ui.info(I18n.t("vagrant.commands.status.output",
                            :states => results.join("\n"),
                            :message => I18n.t("vagrant.commands.status.#{state}")),
                     :prefix => false)

        # Success, exit status 0
        0
       end
    end
  end
end
