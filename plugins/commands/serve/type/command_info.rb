# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    class Type
      class CommandInfo < Type
        class Flag
          TYPES = [:BOOL, :STRING].freeze

          attr_reader :long_name,
            :short_name,
            :default_value,
            :type,
            :description

          def initialize(long_name:, short_name: nil, type:, description: nil)
            @long_name = long_name
            @short_name = short_name
            @description = description
            raise TypeError,
              "Invalid type provided for flag `#{type}'" if !TYPES.include?(type)
            @type = type
          end
        end

        attr_reader :name,
          :help,
          :synopsis,
          :flags,
          :subcommands,
          :primary

        def initialize(name:, help:, synopsis: nil, subcommands: [], primary:)
          @name = name.to_s
          @help = help.to_s
          @synopsis = synopsis.to_s
          @subcommands = Array(subcommands)
          @flags = []
          @primary = primary
        end

        def add_flag(**kwargs)
          @flags << Flag.new(**kwargs)
        end

        def add_subcommand(cmd)
          if !cmd.is_a?(CommandInfo)
            raise TypeError,
              "Expected type `#{CommandInfo.name}' but received `#{cmd.class}'"
          end
          @subcommands << cmd
        end
      end
    end
  end
end
