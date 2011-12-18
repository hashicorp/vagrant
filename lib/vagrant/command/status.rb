require 'optparse'

module Vagrant
  module Command
    class Status < Base
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
        with_target_vms(argv[0]) do |vm|
          if vm.created?
            if vm.vm.accessible?
              state = vm.vm.state.to_s
            else
              state = "inaccessible"
            end
          else
            state = "not_created"
          end

          results << "#{vm.name.to_s.ljust(25)}#{state.gsub("_", " ")}"
        end

        state = results.length == 1 ? state : "listing"

        @env.ui.info(I18n.t("vagrant.commands.status.output",
                            :states => results.join("\n"),
                            :message => I18n.t("vagrant.commands.status.#{state}")),
                     :prefix => false)
      end
    end
  end
end
