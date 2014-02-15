#-------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the MIT License.
#--------------------------------------------------------------------------

require "vagrant"
require_relative "guest_config/config"
require_relative "host_share/config"
module VagrantPlugins
  module HyperV
    class Config < Vagrant.plugin("2", :config)
      # If set to `true`, then VirtualBox will be launched with a GUI.
      #
      # @return [Boolean]
      attr_accessor :gui
      attr_reader :host_share, :guest

      def host_config(&block)
        block.call(@host_share)
      end

      def guest_config(&block)
        block.call(@guest)
      end

      def finalize!
        @gui = nil if @gui == UNSET_VALUE
      end

      def initialize(region_specific=false)
        @gui = UNSET_VALUE
        @host_share = HostShare::Config.new
        @guest = GuestConfig::Config.new
      end

      def validate(machine)
        errors = _detected_errors
        unless host_share.valid_config?
          errors << host_share.errors.flatten.join(" ")
        end

        unless guest.valid_config?
          errors << guest.errors.flatten.join(" ")
        end
        { "HyperV" => errors }
      end

    end
  end
end
