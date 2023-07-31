# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module Vagrant
  module Util
    module Remote
      # This module modifies the SSH methods for server mode, where we can't
      # assume stdio or exec will work as expected.
      module SSH
        module ClassMethods
          def _raw_exec(ssh, command_options, ssh_info, opts)
            raise "ssh exec is not yet implemented in server mode"
          end

          def _raw_subprocess(ssh, command_options, ssh_info, opts)
            subprocess_opts = {
              notify: [:stdout, :stderr]
            }

            if ssh_info[:forward_env]
              subprocess_opts[:env] = {}
              ssh_info[:forward_env].each do |key|
                subprocess_opts[:env][key] = ENV[key]
              end
            end

            command_options.append(subprocess_opts)

            Vagrant::Util::Subprocess.execute(ssh, *command_options) do |type, output|
              # TODO(phinze): For now we're collapsing stderr and stdout, because
              # we don't (yet!) have a way of sending stderr back through
              # terminal.UI. Once we plumb through that capability we should be
              # able to switch on type here so things are printed where they go.
              opts[:ui].client.output output
            end
          end
        end

        def self.prepended(base)
          base.singleton_class.prepend(ClassMethods)
        end
      end
    end
  end
end
