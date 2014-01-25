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
            if !machine.box
              machine.ui.output(I18n.t(
                "vagrant.errors.box_update_no_box",
                name: machine.config.vm.box))
              next
            end

            box = machine.box
            update = box.has_update?(machine.config.vm.box_version)
            if !update
              machine.ui.success(I18n.t(
                "vagrant.box_up_to_date_single",
                name: box.name, version: box.version))
              next
            end

            @env.action_runner.run(Vagrant::Action.action_box_add, {
              box_url: box.metadata_url,
              box_provider: update[2].name,
              box_version: update[1].version,
              ui: machine.ui,
            })
          end
        end
      end
    end
  end
end
