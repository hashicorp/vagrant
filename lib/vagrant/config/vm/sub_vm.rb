module Vagrant
  module Config
    class VMConfig < Base
      # Represents a single sub-VM in a multi-VM environment.
      class SubVM
        include Util::StackedProcRunner

        attr_reader :options

        def initialize
          @options = {}
        end
      end
    end
  end
end

