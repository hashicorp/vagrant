module VagrantPlugins
  module HostVoid
    module Cap
      class Dummy
        def self.dummy(bag, ui, argument)
          ui.info "Dummy host cap in ruby runtime, sent argument: `#{argument}' with bag: #{bag}"
          "this is a result value string!"
        end
      end
    end
  end
end
