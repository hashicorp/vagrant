module VagrantPlugins
  module HostVoid
    module Cap
      class Dummy
        def self.dummy(ui, argument)
          raise "got argument: #{ui.inspect} and #{argument.inspect}"
        end
      end
    end
  end
end
