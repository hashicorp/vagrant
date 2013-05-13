module Vagrant
  module Action
    module Builtin
      # This class asks the user to confirm some sort of question with
      # a "Y/N" question. The only parameter is the text to ask the user.
      # The result is placed in `env[:result]` so that it can be used
      # with the {Call} class.
      class Confirm
        # For documentation, read the description of the {Confirm} class.
        #
        # @param [String] message The message to ask the user.
        # @param [Symbol] force_key The key that if present and true in
        #   the environment hash will skip the confirmation question.
        def initialize(app, env, message, force_key=nil)
          @app      = app
          @message  = message
          @force_key = force_key
        end

        def call(env)
          choice = nil

          # If we have a force key set and we're forcing, then set
          # the result to "Y"
          choice = "Y" if @force_key && env[@force_key]

          # If we haven't chosen yes, then ask the user via TTY
          choice = env[:ui].ask(@message) if !choice

          # The result is only true if the user said "Y"
          env[:result] = choice && choice.upcase == "Y"

          @app.call(env)
        end
      end
    end
  end
end
