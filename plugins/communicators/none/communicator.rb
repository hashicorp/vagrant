# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

require "log4r"
require "vagrant"

module VagrantPlugins
  module CommunicatorNone
    # This class provides no communication with the VM.
    # It allows Vagrant to manage a machine lifecycle
    # while not actually connecting to it. The communicator
    # stubs out all methods to be successful allowing
    # Vagrant to proceed "as normal" without actually
    # doing anything.
    class Communicator < Vagrant.plugin("2", :communicator)
      def self.match?(_)
        # Any machine can be not communicated with
        true
      end

      def initialize(_)
        @logger = Log4r::Logger.new(self.class.name.downcase)
      end

      def ready?
        @logger.debug("#ready? stub called on none")
        true
      end

      def execute(*_)
        @logger.debug("#execute stub called on none")
        0
      end

      def sudo(*_)
        @logger.debug("#sudo stub called on none")
        0
      end

      def test(*_)
        @logger.debug("#test stub called on none")
        true
      end
    end
  end
end
