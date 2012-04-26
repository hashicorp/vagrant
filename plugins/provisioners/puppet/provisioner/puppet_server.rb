module VagrantPlugins
  module Puppet
    module Provisioner
      I18N_NAMESPACE = "vagrant.provisioners.puppet_server"
      class PuppetServerError < Vagrant::Errors::VagrantError
        error_namespace(I18N_NAMESPACE)
      end

      class PuppetServer < Base
        class Config < Vagrant::Config::Base
          attr_accessor :puppet_server
          attr_accessor :puppet_node
          attr_accessor :options
          attr_accessor :facter
          attr_accessor :client_certificate
          attr_accessor :client_private_key
          attr_accessor :client_certificate_path
          attr_accessor :client_private_key_path

          def facter; @facter ||= {}; end
          def puppet_server; @puppet_server || "puppet"; end
          def options; @options ||= []; end
          def has_cert?
            client_certificate || client_certificate_path
          end

          def has_key?
            client_private_key || client_private_key_path
          end

          def validate(env, errors)
            if (has_key? && !has_cert?) || (!has_key? && has_cert?)
              errors.add(translate_message(:cert_and_key))
            end
            if (client_certificate && client_certificate_path)
              errors.add(translate_message(:cert_inline_and_path_clash))
            end
            if (client_private_key && client_private_key_path)
              errors.add(translate_message(:key_inline_and_path_clash))
            end
            if (has_key? || has_cert?) && !puppet_node
              errors.add(translate_message(:cert_requires_node))
            end
          end

          def translate_message(name)
            I18n.t("#{I18N_NAMESPACE}.#{name}")
          end
        end

        def self.config_class
          Config
        end

        def provision!
          verify_binary("puppetd")
          setup_ssl if config.has_cert?
          run_puppetd_client
        end

        def verify_binary(binary)
          env[:vm].channel.sudo("which #{binary}",
                                :error_class => PuppetServerError,
                                :error_key => :not_detected,
                                :binary => binary)
        end

        def with_pem_file(name)
          file = Tempfile.new(name.to_s)
          begin
            file.write(config.send(name).gsub(/^ */m, ''))
            file.fsync
            yield file.path
          ensure
            file.close
            file.unlink
          end
        end

        def setup_ssl
          env[:ui].info config.translate_message(:setting_up_ssl)
          cn = config.puppet_node
          tmp_path = "/tmp/#{cn}.pem.#{Time.now.to_i}"

          # Ensures the /var/lib/puppet/ssl directory tree is created
          env[:vm].channel.sudo("puppet agent --certname #{cn} --fingerprint; true")

          env[:ui].info config.translate_message(:upload_client_certificate)
          if config.client_certificate
            with_pem_file :client_certificate do |path|
              env[:vm].channel.upload(path.to_s, tmp_path)
            end
          else
            path = File.expand_path(config.client_certificate_path)
            env[:vm].channel.upload(path, tmp_path)
          end
          env[:vm].channel.sudo("mv #{tmp_path} /var/lib/puppet/ssl/certs/#{cn}.pem")

          env[:ui].info config.translate_message(:upload_client_private_key)
          if config.client_private_key
            with_pem_file :client_private_key do |path|
              env[:vm].channel.upload(path.to_s, tmp_path)
            end
          else
            path = File.expand_path(config.client_private_key_path)
            env[:vm].channel.upload(path, tmp_path)
          end
          env[:vm].channel.sudo("mv #{tmp_path} /var/lib/puppet/ssl/private_keys/#{cn}.pem")
        end

        def run_puppetd_client
          options = config.options
          options = [options] if !options.is_a?(Array)

          # Intelligently set the puppet node cert name based on certain
          # external parameters.
          cn = nil
          if config.puppet_node
            # If a node name is given, we use that directly for the certname
            cn = config.puppet_node
          elsif env[:vm].config.vm.host_name
            # If a host name is given, we explicitly set the certname to
            # nil so that the hostname becomes the cert name.
            cn = nil
          else
            # Otherwise, we default to the name of the box.
            cn = env[:vm].config.vm.box
          end

          # Add the certname option if there is one
          options += ["--certname", cn] if cn
          options = options.join(" ")

          # Build up the custom facts if we have any
          facter = ""
          if !config.facter.empty?
            facts = []
            config.facter.each do |key, value|
              facts << "FACTER_#{key}='#{value}'"
            end

            facter = "#{facts.join(" ")} "
          end

          command = "#{facter}puppetd #{options} --server #{config.puppet_server}"

          env[:ui].info config.translate_message(:running_puppetd)
          env[:vm].channel.sudo(command) do |type, data|
            env[:ui].info(data.chomp, :prefix => false)
          end
        end
      end
    end
  end
end
