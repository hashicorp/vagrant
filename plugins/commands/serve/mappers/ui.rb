# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    class Mappers
      # Build a remote UI from terminal UI client
      class UIFromTerminal < Mapper
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

      class UIToTerminal < Mapper
        def initialize
          super(
            inputs: [Input.new(type: Vagrant::UI::Interface)],
            output: Client::Terminal,
            func: method(:converter),
          )
        end

        def converter(ui)
          ui.client
        end
      end

      class UIPrefixedToTerminal < Mapper
        def initialize
          super(
            inputs: [Input.new(type: Vagrant::UI::Prefixed)],
            output: Client::Terminal,
            func: method(:converter),
          )
        end

        def converter(ui)
          ui.client
        end
      end
    end
  end
end
