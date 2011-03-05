module Vagrant
  module Systems
    class Linux < Vagrant::Systems::Base
      # A custom config class which will be made accessible via `config.linux`
      # This is not necessary for all system implementers, of course. However,
      # generally, Vagrant tries to make almost every aspect of its execution
      # configurable, and this assists that goal.
      class LinuxConfig < Vagrant::Config::Base
        configures :linux

        attr_accessor :halt_timeout
        attr_accessor :halt_check_interval

        def initialize
          @halt_timeout = 30
          @halt_check_interval = 1
        end
      end
    end
  end
end
