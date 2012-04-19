require "vagrant"

module VagrantPlugins
  module Kernel
    class VagrantConfig < Vagrant::Config::V1::Base
      attr_accessor :dotfile_name
      attr_accessor :host
    end
  end
end
