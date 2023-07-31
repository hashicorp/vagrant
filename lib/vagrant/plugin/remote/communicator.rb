# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module Vagrant
  module Plugin
    module Remote
      class Communicator < V2::Communicator
        # Add an attribute accesor for the client
        # when applied to the Communicator class
        attr_accessor :client

        def initialize(machine, **kwargs)
          @logger = Log4r::Logger.new("vagrant::remote::communicator")
          @logger.debug("initializing communicator with remote backend")
          @machine = machine
          @client = kwargs.fetch(:client, machine.client.communicate)
          if @client.nil?
            raise ArgumentError,
              "Remote client is required for `#{self.class.name}`"
          end
        end

        def ready?
          @logger.debug("remote communicator, checking if it's ready")
          @client.ready(@machine)
        end

        def wait_for_ready(time)
          @logger.debug("remote communicator, waiting for ready")
          @client.wait_for_ready(@machine, time)
        end

        def download(from, to)
          @logger.debug("remote communicator, downloading #{from} -> #{to}")
          @client.download(@machine, from, to)
        end

        def upload(from, to)
          @logger.debug("remote communicator, uploading #{from} -> #{to}")
          @client.upload(@machine, from, to)
        end

        def execute(cmd, opts=nil, &block)
          @logger.debug("remote communicator, executing command")
          res = @client.execute(@machine, cmd, opts)
          yield :stdout, res.stdout if block_given?
          yield :stderr, res.stderr if block_given?
          res.exit_code
        end

        def sudo(cmd, opts=nil, &block)
          @logger.debug("remote communicator, executing (privileged) command")
          res = @client.privileged_execute(@machine, cmd, opts)
          yield :stdout, res.stdout if block_given?
          yield :stderr, res.stderr if block_given?
          res.exit_code
        end

        def test(cmd, opts=nil)
          @logger.debug("remote communicator, testing command")
          @client.test(@machine, cmd, opts)
        end

        def reset!
          @logger.debug("remote communicator, reseting")
          @client.reset(@machine)
        end

        def to_proto
          client.proto
        end
      end
    end
  end
end
