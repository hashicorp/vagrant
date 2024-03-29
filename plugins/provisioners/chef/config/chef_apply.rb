# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

require "vagrant/util/presence"

require_relative "base"

module VagrantPlugins
  module Chef
    module Config
      class ChefApply < Base
        include Vagrant::Util::Presence

        # The raw recipe text (as a string) to execute via chef-apply.
        # @return [String]
        attr_accessor :recipe

        # The path (on the guest) where the uploaded apply recipe should be
        # written (/tmp/vagrant-chef-apply-#.rb).
        # @return [String]
        attr_accessor :upload_path

        def initialize
          super

          @recipe      = UNSET_VALUE
          @upload_path = UNSET_VALUE
        end

        def finalize!
          super

          @recipe = nil if @recipe == UNSET_VALUE
          @upload_path = "/tmp/vagrant-chef-apply" if @upload_path == UNSET_VALUE
        end

        def validate(machine)
          errors = validate_base(machine)

          if !present?(recipe)
            errors << I18n.t("vagrant.provisioners.chef.recipe_empty")
          end

          if !present?(upload_path)
            errors << I18n.t("vagrant.provisioners.chef.upload_path_empty")
          end

          { "chef apply provisioner" => errors }
        end
      end
    end
  end
end
