# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module Vagrant
  module Plugin
    module Remote
      class Command < V2::Command
        # Add an attribute accesor for the client
        # when applied to the Command class
        attr_accessor :client

        def initialize(argv, env, **kwargs)
          @logger = Log4r::Logger.new("vagrant::remote::command")
          @logger.debug("initializing command with remote backend")
          @argv = argv
          @env  = env
          @client = kwargs.delete(:client)
          if @client.nil?
            raise ArgumentError,
              "Remote client is required for `#{self.class.name}`"
          end
        end

        def execute
          client.execute(@argv)
        end
      end
    end
  end
end
