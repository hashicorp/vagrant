require 'log4r'

module Vagrant
  module Plugin
    module V2
      # This is the base class for a trigger for the V2 API. A provisioner
      # is primarily responsible for installing software on a Vagrant guest.
      class Trigger
        attr_reader :config

        # Trigger
        #
        # @param [Object] env Vagrant environment
        # @param [Object] config Trigger configuration
        def initialize(env, config)
          @env = env
          @config  = config
          @logger = Log4r::Logger.new("vagrant::trigger::#{self.class.to_s.downcase}")
        end
      end
    end
  end
end
