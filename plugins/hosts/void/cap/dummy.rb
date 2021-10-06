module VagrantPlugins
  module HostVoid
    module Cap
      class Dummy
        def self.dummy(ui, argument)
          ui.info "Dummy host cap in ruby runtime, sent argument: #{argument}"
          true
        end
      end
    end
  end
end
