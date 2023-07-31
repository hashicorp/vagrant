# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    class Type
      class CommandArguments < Type

        attr_reader :arguments, :flags

        def initialize(args: nil, flags: nil, value: nil)
          if args.nil? && flags.nil? && value.nil?
            raise ArgumentError,
              "Args and flags or value is required"
          end
          if value && (!value.respond_to?(:flags) || !value.respond_to?(:args))
            raise TypeError,
              "Value provided must respond to #flags and #args"
          end
          if value
            @arguments = Array(value.args)
            @flags = value.flags || {}
          else
            @arguments = Array(args)
            @flags = flags || {}
          end

          @arguments.each do |v|
            if !v.is_a?(String)
              raise TypeError,
                "Expecting `String' type for argument, received `#{v.class}'"
            end
          end

          if !@flags.is_a?(Hash)
            raise TypeError,
              "Expecting `Hash' type for flags, received `#{@flags.class}'"
          end

          @flags.each_pair do |k,v|
            if !k.is_a?(String) && !k.is_a?(Symbol)
              raise TypeError,
                "Expecting `String' or `Symbol' for flag key, received `#{k.class}'"
            end
            if !v.is_a?(String) && !v.is_a?(TrueClass) && !v.is_a?(FalseClass) && !v.is_a?(Symbol)
              raise TypeError,
                "Expecting `String' or `Boolean' for flag value, received `#{v.class}'"
            end
          end
        end

        def value
          arguments +
            flags.map { |k,v|
              if v == true
                "--#{k}"
              elsif v == false
                "--no-#{k}"
              else
                "--#{k}=#{v}"
              end
            }
        end
      end
    end
  end
end
