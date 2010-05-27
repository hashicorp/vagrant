module Vagrant
  module Actions
    module VM
      class Start < Base
        def prepare
          # Start is a "meta-action" so it really just queues up a bunch
          # of other actions in its place:
          steps = [Boot]
          if !@runner.vm || !@runner.vm.saved?
            steps.unshift([Customize, ForwardPorts, SharedFolders])
            steps << Provision if !@runner.env.config.vm.provisioner.nil? && options[:provision]
          end

          steps.flatten.each do |action_klass|
            @runner.add_action(action_klass, options)
          end
        end
      end
    end
  end
end
