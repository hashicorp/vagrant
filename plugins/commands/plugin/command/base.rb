require "vagrant/plugin/state_file"

module VagrantPlugins
  module CommandPlugin
    module Command
      class Base < Vagrant.plugin("2", :command)
        # This is a helper for executing an action sequence with the proper
        # environment hash setup so that the plugin specific helpers are
        # in.
        #
        # @param [Object] callable the Middleware callable
        # @param [Hash] env Extra environment hash that is merged in.
        def action(callable, env=nil)
          @env.action_runner.run(callable, env)
        end
      end
    end
  end
end
