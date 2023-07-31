# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module Vagrant
  module Config
    module V2
      # This is a configuration object that can have anything done
      # to it. Anything, and it just appears to keep working.
      class DummyConfig < Vagrant::Plugin::V2::Config
        LOG  = Log4r::Logger.new("vagrant::config::v2::dummy_config")

        def method_missing(name, *args, &block)
          # There are a few scenarios where ruby will attempt to implicity
          # coerce a given object into a certain type. DummyConfigs can end up
          # in some of these scenarios when they're being shipped around in
          # callbacks with splats. If method_missing allows these methods to be
          # called but continues to return DummyConfig back, Ruby will raise a
          # TypeError. Doing the normal thing of raising NoMethodError allows
          # DummyConfig to behave normally as its being passed through splats.
          #
          # For a bit more detail and some keywords for further searching, see:
          # https://ruby-doc.org/core-2.7.2/doc/implicit_conversion_rdoc.html
          if [:to_hash, :to_ary].include?(name)
            return super
          end

          # Trying to define a variable
          if name.to_s.match(/^[\w]*=/)
            LOG.debug("found name #{name}")
            LOG.debug("setting instance variable name #{name.to_s.split("=")[0]}")
            var_name = "@#{name.to_s.split("=")[0]}"
            self.instance_variable_set(var_name, args[0])
          else
            DummyConfig.new
          end
        end

        def merge(c)
          c
        end

        def set_options(options)
          options.each do |key, value|
            if key.to_s.match(/^[\w]*=/)
              var_name = "@#{key.to_s}"
              self.instance_variable_set(var_name, value)
            end
          end
        end

        def instance_variables_hash
          instance_variables.inject({}) do |acc, iv|
            acc[iv.to_s[1..-1]] = instance_variable_get(iv)
            acc
          end
        end
      end
    end
  end
end
