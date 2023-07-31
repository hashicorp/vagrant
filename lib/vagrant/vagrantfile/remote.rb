# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

# lib/remote.rb

module Vagrant
  class Vagrantfile
    module Remote
      # Add an attribute reader for the client
      # when applied to the Machine class
      def self.prepended(klass)
        klass.class_eval do
          attr_reader :client
        end
      end

      def initialize(*_, client:)
        @client = client
        @config = ConfigWrapper.new(client: client)
      end

      # @return [Machine]
      def machine(name, provider, _, _, _)
        client.machine(name, provider)
      end

      def machine_names
        client.target_names
      end

      def machine_config(name, provider, _, _,  validate_provider=true)
        client.machine_config(name, provider, validate_provider)
      end
    end

    class ConfigWrapper
      def initialize(client:)
        @client = client
        @logger = Log4r::Logger.new(self.class.name.downcase)
        @root = Vagrant::Config::V2::Root.new(Vagrant.plugin("2").local_manager.config)
      end

      def method_missing(*args, **opts, &block)
        case args.size
        when 1
          namespace = args.first
          ConfigFetcher.new(namespace, client: @client)
        when 2
          if args.first.to_s != "[]"
            raise ArgumentError,
                  "Expected #[] but received ##{args.first} on config wrapper"
          end
          namespace = args.last
          ConfigFetcher.new(namespace, client: @client)
        else
          @logger.trace("cannot handle wrapped config request for #{args.inspect}, sending to root")
          @root.send(*args, **opts, &block)
        end
      end
    end

    class ConfigFetcher < BasicObject
      def initialize(namespace, client:)
        @namespace = namespace
        @client = client
        @logger = ::Log4r::Logger.new("vagrant::vagrantfile::remote::configfetcher")
      end

      def method_missing(*args, **opts, &block)
        begin
          return @client.get_value(@namespace, args.last) if
            (args.size == 2 && args.first.to_sym == :[]) ||
            args.size == 1
        rescue => err
          @logger.trace("failed to get config value from remote, calling direct (#{err})")
          return @client.get_config(@namespace).send(*args, **opts, &block)
        end

        @client.get_config(@namespace).send(*args, **opts, &block)
      end
    end
  end
end
