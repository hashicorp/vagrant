# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

Vagrant.require "log4r"

module Vagrant
  module Action
    module Builtin
      # This middleware will remove a box for a given provider.
      class BoxRemove
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant::action::builtin::box_remove")
        end

        def call(env)
          box_name     = env[:box_name]
          box_architecture = env[:box_architecture] if env[:box_architecture]
          box_provider = env[:box_provider].to_sym if env[:box_provider]
          box_version  = env[:box_version]
          box_remove_all_versions = env[:box_remove_all_versions]
          box_remove_all_providers = env[:box_remove_all_providers]
          box_remove_all_architectures = env[:box_remove_all_architectures]

          box_info = Util::HashWithIndifferentAccess.new
          env[:box_collection].all.each do |name, version, provider, architecture|
            next if name != box_name
            box_info[version] ||= Util::HashWithIndifferentAccess.new
            box_info[version][provider] ||= []
            box_info[version][provider] << architecture
          end

          # If there's no box info, then the box doesn't exist here
          if box_info.empty?
            raise Errors::BoxRemoveNotFound, name: box_name
          end

          # Filtering only matters if not removing all versions
          if !box_remove_all_versions
            # If no version was provided, and not removing all versions,
            # only allow one version to proceed
            if !box_version && box_info.size > 1
              raise Errors::BoxRemoveMultiVersion,
                name: box_name,
                versions: box_info.keys.sort.map { |k| " * #{k}" }.join("\n")
            end

            # If a version was provided, make sure it exists
            if box_version
              if !box_info.keys.include?(box_version)
                raise Errors::BoxRemoveVersionNotFound,
                  name: box_name,
                  version: box_version,
                  versions: box_info.keys.sort.map { |k| " * #{k}" }.join("\n")
              else
                box_info.delete_if { |k, _| k != box_version }
              end
            end

            # Only a single version remains
            box_version = box_info.keys.first

            # Further filtering only matters if not removing all providers
            if !box_remove_all_providers
              # If no provider was given, check if there are more
              # than a single provider for the version
              if !box_provider && box_info.values.first.size > 1
                raise Errors::BoxRemoveMultiProvider,
                  name: box_name,
                  version: box_version,
                  providers: box_info.values.first.keys.map(&:to_s).sort.join(", ")
              end

              # If a provider was given, check the version has it
              if box_provider
                if !box_info.values.first.key?(box_provider)
                  raise Errors::BoxRemoveProviderNotFound,
                    name: box_name,
                    version: box_version,
                    provider: box_provider.to_s,
                    providers: box_info.values.first.keys.map(&:to_s).sort.join(", ")
                else
                  box_info.values.first.delete_if { |k, _| k.to_s != box_provider.to_s }
                end
              end

              # Only a single provider remains
              box_provider = box_info.values.first.keys.first

              # Further filtering only matters if not removing all architectures
              if !box_remove_all_architectures
                # If no architecture was given, check if there are more
                # than a single architecture for the provider in version
                if !box_architecture && box_info.values.first.values.first.size > 1
                  raise Errors::BoxRemoveMultiArchitecture,
                    name: box_name,
                    version: box_version,
                    provider: box_provider.to_s,
                    architectures: box_info.values.first.values.first.sort.join(", ")
                end

                # If architecture was given, check the provider for the version has it
                if box_architecture
                  if !box_info.values.first.values.first.include?(box_architecture)
                    raise Errors::BoxRemoveArchitectureNotFound,
                      name: box_name,
                      version: box_version,
                      provider: box_provider.to_s,
                      architecture: box_architecture,
                      architectures: box_info.values.first.values.first.sort.join(", ")
                  else
                    box_info.values.first.values.first.delete_if { |v| v != box_architecture }
                  end
                end
              end
            end
          end

          box_info.each do |version, provider_info|
            provider_info.each do |provider, architecture_info|
              provider = provider.to_sym
              architecture_info.each do |architecture|
                box = env[:box_collection].find(
                  box_name, provider, version, architecture
                )

                # Verify that this box is not in use by an active machine,
                # otherwise warn the user.
                users = box.in_use?(env[:machine_index]) || []
                users = users.find_all { |u| u.valid?(env[:home_path]) }
                if !users.empty?
                  # Build up the output to show the user.
                  users = users.map do |entry|
                    "#{entry.name} (ID: #{entry.id})"
                  end.join("\n")

                  force_key = :force_confirm_box_remove
                  message   = I18n.t(
                    "vagrant.commands.box.remove_in_use_query",
                    name: box.name,
                    architecture: box.architecture,
                    provider: box.provider,
                    version: box.version,
                    users: users) + " "

                  # Ask the user if we should do this
                  stack = Builder.new.tap do |b|
                    b.use Confirm, message, force_key
                  end

                  # Keep used boxes, even if "force" is applied
                  keep_used_boxes = env[:keep_used_boxes]

                  result = env[:action_runner].run(stack, env)
                  if !result[:result] || keep_used_boxes
                    # They said "no", so continue with the next box
                    next
                  end
                end

                env[:ui].info(I18n.t("vagrant.commands.box.removing",
                  name: box.name,
                  architecture: box.architecture,
                  provider: box.provider,
                  version: box.version))

                box.destroy!
                env[:box_collection].clean(box.name)

                # Passes on the removed box to the rest of the middleware chain
                env[:box_removed] = box
              end
            end
          end

          @app.call(env)
        end
      end
    end
  end
end
