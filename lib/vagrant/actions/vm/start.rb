module Vagrant
  module Actions
    module VM
      class Start < Base
        def prepare
          # Start is a "meta-action" so it really just queues up a bunch
          # of other actions in its place:
          steps = [ForwardPorts, SharedFolders, Boot]
          steps.unshift(Customize) unless @runner.vm.saved?

          steps.each do |action_klass|
            @runner.add_action(action_klass)
          end
        end
      end
    end
  end
end
