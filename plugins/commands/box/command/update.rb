require 'optparse'

module VagrantPlugins
  module CommandBox
    module Command
      class Update < Vagrant.plugin("2", :command)
        def execute
          options = {}

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant box update [options]"
            o.separator ""
            o.separator "Updates the box that is in use in the current Vagrant environment,"
            o.separator "if there any updates available. This does not destroy/recreate the"
            o.separator "machine, so you'll have to do that to see changes."
            o.separator ""
            o.separator "To update a specific box (not tied to a Vagrant environment), use the"
            o.separator "--box flag."
            o.separator ""
            o.separator "Options:"
            o.separator ""

            o.on("--box VALUE", String, "Update a specific box") do |b|
              options[:box] = b
            end
          end

          argv = parse_options(opts)
          return if !argv

          with_target_vms(argv) do |machine|
            @env.action_runner.run(Vagrant::Action.action_box_update, {
              box_outdated_force: true,
              box_outdated_refresh: true,
              box_outdated_success_ui: true,
              machine: machine,
            })
          end
        end
      end
    end
  end
end
