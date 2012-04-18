require "vagrant"

module VagrantPlugins
  module Kernel
    class VagrantConfig < Vagrant::Config::V1::Base
      attr_accessor :dotfile_name
      attr_accessor :host

      def initialize
        @dotfile_name = UNSET_VALUE
        @host         = UNSET_VALUE
      end
    end
  end
end
