require 'optparse'

module VagrantPlugins
  module CommandStatus
    class Command < Vagrant.plugin("2", :command)
      def execute
        options = {}

        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant status [machine-name] [-t]"
        end

        opts.on_tail("-t", "Output in machine-readable format") do |c|
          options[:command] = "t"
        end

        # Parse the options
        argv = parse_options(opts)
        return if !argv

        state = nil
        results = []
        with_target_vms(argv) do |machine|
          
          unless options[:command] == "t"
            state = machine.state if !state
            separator= [:ljust,25]
          else
             separator = [:+,","]
          end
          
          results << "#{machine.name.to_s.send(*separator)}#{machine.state.short_description} (#{machine.provider_name})"
        end

        if options[:command] == "t"
          @env.ui.info(results.join("\n"))
          return 0
        end


        message = nil
        if results.length == 1
          message = state.long_description
        else
          message = I18n.t("vagrant.commands.status.listing")
        end

        @env.ui.info(I18n.t("vagrant.commands.status.output",
                            :states => results.join("\n"),
                            :message => message),
                     :prefix => false)

        # Success, exit status 0
        0
      end
    end
  end
end
