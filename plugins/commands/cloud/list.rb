require 'optparse'

module VagrantPlugins
  module CloudCommand
    module Command
      class List < Vagrant.plugin("2", :command)
        def execute
          options = {}

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant cloud list [options] organization"
            o.separator ""
            o.separator "Search for boxes managed by a specific user/organization"
            o.separator ""
            o.separator "Options:"
            o.separator ""

            o.on("-j", "--json", "Formats results in JSON") do |j|
              options[:check] = j
            end
            o.on("-l", "--limit", Integer, "Max number of search results (default is 25)") do |l|
              options[:check] = l
            end
            o.on("-p", "--provider", "Comma separated list of providers to filter search. Defaults to all.") do |p|
              options[:check] = p
            end
            o.on("-s", "--sort-by", "Column to sort list (created, downloads, updated)") do |s|
              options[:check] = s
            end
            o.on("-u", "--username USERNAME_OR_EMAIL", String, "Vagrant Cloud username or email address") do |t|
              options[:username] = u
            end
          end

          # Parse the options
          argv = parse_options(opts)
          return if !argv
          if argv.length > 1
            raise Vagrant::Errors::CLIInvalidUsage,
              help: opts.help.chomp
          end

          @client = VagrantPlugins::CloudCommand::Util.client_login(@env, options[:username])

          # TODO: This endpoint is not implemented yet

          0
        end
      end
    end
  end
end
