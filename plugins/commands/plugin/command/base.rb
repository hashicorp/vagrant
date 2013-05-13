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
          env = {
            :gem_helper => GemHelper.new(@env.gems_path),
            :plugin_state_file => StateFile.new(@env.home_path.join("plugins.json"))
          }.merge(env || {})

          @env.action_runner.run(callable, env)
        end
      end
    end
  end
end
