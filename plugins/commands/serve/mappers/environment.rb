module VagrantPlugins
  module CommandServe
    class Mappers
      class EnvironmentFromProject < Mapper
        def initialize
          inputs = [
            Input.new(type: Client::Project),
            Input.new(type: Vagrant::UI::Remote),
          ]
          super(inputs: inputs, output: Vagrant::Environment, func: method(:converter))
        end

        def converter(project, ui)
          Vagrant::Environment.new(ui: ui, client: project)
        end
      end
    end
  end
end
