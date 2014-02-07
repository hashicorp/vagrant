module Vagrant
  module Action
    module Builtin
      class HandleBoxUrl < HandleBox
        def call(env)
          env[:ui].warn("HandleBoxUrl middleware is deprecated. Use HandleBox instead.")
          env[:ui].warn("This is a bug with the provider. Please contact the creator")
          env[:ui].warn("of the provider you use to fix this.")
          super
        end
      end
    end
  end
end
