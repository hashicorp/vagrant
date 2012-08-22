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
        def initialize(app, env, message)
          @app      = app
          @message  = message
        end

        def call(env)
          # Ask the user the message and store the result
          choice = nil
          choice = env[:ui].ask(@message)
          env[:result] = choice && choice.upcase == "Y"

          @app.call(env)
        end
      end
    end
  end
end
