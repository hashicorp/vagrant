module VagrantPlugins
  module CommandServe
    class Mappers
      # Build a remote UI from terminal UI client
      class UIFromClient < Mapper
        def initialize
          super(
            inputs: [Input.new(type: Client::Terminal)],
            output: Vagrant::UI::Remote,
            func: method(:converter)
          )
        end

        def converter(client)
          Vagrant::UI::Remote.new(client)
        end
      end
    end
  end
end
