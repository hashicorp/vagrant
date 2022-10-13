module Vagrant
  module Action
    module Builtin
      # This class is used within the Builder class for injecting triggers into
      # different parts of the call stack.
      class Trigger
        # @param [Class, String, Symbol] name Name of trigger to fire
        # @param [Vagrant::Plugin::V2::Triger] triggers Trigger object
        # @param [Symbol] timing When trigger should fire (:before/:after)
        # @param [Symbol] type Type of trigger
        def initialize(app, env, name, triggers, timing, type=:action, all: false)
          @app         = app
          @env         = env
          @triggers    = triggers
          @name        = name
          @timing      = timing
          @type        = type
          @all         = all

          if ![:before, :after].include?(timing)
            raise ArgumentError,
              "Invalid value provided for `timing` (allowed: :before or :after)"
          end
        end

        def call(env)
          machine = env[:machine]
          machine_name = machine.name if machine

          @triggers.fire(@name, @timing, machine_name, @type, all: @all)
          # Carry on
          @app.call(env)
        end
      end
    end
  end
end
