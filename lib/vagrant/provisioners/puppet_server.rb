module Vagrant
  module Provisioners
    class PuppetServerError < Vagrant::Errors::VagrantError
      error_namespace("vagrant.provisioners.puppet_server")
    end

    class PuppetServer < Base
      class Config < Vagrant::Config::Base
        attr_accessor :puppet_server
        attr_accessor :puppet_node
        attr_accessor :options
        attr_accessor :facter
        attr_accessor :client_certificate
        attr_accessor :client_private_key

        def facter; @facter ||= {}; end
        def puppet_server; @puppet_server || "puppet"; end
        def options; @options ||= []; end

        def validate(env, errors)
          if (client_private_key && !client_certificate) ||
            (!client_private_key && client_certificate)
            errors.add(I18n.t("vagrant.provisioners.puppet_server.cert_and_key"))
          end
          if (client_private_key || client_certificate) && !puppet_node
            errors.add(I18n.t("vagrant.provisioners.puppet_server.cert_requires_node"))
          end
        end
      end

      def self.config_class
        Config
      end

      def provision!
        verify_binary("puppetd")
        setup_ssl
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
        if config.client_certificate && config.client_private_key
          cn = config.puppet_node

          # will fail but creates the /var/lib/puppet/ssl directory tree
          env[:vm].channel.sudo("puppet agent --certname #{cn} --test; true")

          with_pem_file :client_certificate do |path|
            env[:vm].channel.upload(path.to_s, "/tmp/#{cn}.pem")
            env[:vm].channel.sudo("mv /tmp/#{cn}.pem /var/lib/puppet/ssl/certs/#{cn}.pem")
          end
          with_pem_file :client_private_key do |path|
            env[:vm].channel.upload(path.to_s, "/tmp/#{cn}.pem")
            env[:vm].channel.sudo("mv /tmp/#{cn}.pem /var/lib/puppet/ssl/private_keys/#{cn}.pem")
          end
        end
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

        env[:ui].info I18n.t("vagrant.provisioners.puppet_server.running_puppetd")
        env[:vm].channel.sudo(command) do |type, data|
          env[:ui].info(data.chomp, :prefix => false)
        end
      end
    end
  end
end
