require 'vagrant/util/template_renderer'

module Vagrant
  module Hosts
    # Base class representing a host machine. These classes
    # define methods which may have host-specific (Mac OS X, Windows,
    # Linux, etc) behavior. The class is automatically determined by
    # default but may be explicitly set via `config.vagrant.host`.
    class Base
      # The {Environment} which this host belongs to.
      attr_reader :env

      # Loads the proper host for the given value. If the value is nil
      # or is the symbol `:detect`, then the host class will be detected
      # using the `RUBY_PLATFORM` constant.
      #
      # @param [Environment] env
      # @param [String] klass
      # @return [Base]
      def self.load(env, klass)
        klass = detect if klass.nil? || klass == :detect
        return nil if !klass
        return klass.new(env)
      end

      # Detects the proper host class for current platform and returns
      # the class.
      #
      # @return [Class]
      def self.detect
        [BSD, Linux].each do |type|
          result = type.distro_dispatch
          return result if result
        end

        nil
      rescue Exception
        nil
      end

      # This must be implemented by subclasses to dispatch to the proper
      # distro-specific class for the host. If this returns nil then it is
      # an invalid host class.
      def self.distro_dispatch
        nil
      end

      # Initialzes a new host. This method shouldn't be called directly,
      # typically, since it will be called by {Environment#load!}.
      #
      # @param [Environment] env
      def initialize(env)
        @env = env
      end

      # Returns true of false denoting whether or not this host supports
      # NFS shared folder setup. This method ideally should verify that
      # NFS is installed.
      #
      # @return [Boolean]
      def nfs?
        false
      end

      # Check if the exports file already contains the proper information if
      # such information can be ascertained without using sudo.
      #
      # @param [String] output The rendered output of a template.
      def check_exports_file(output)
        begin
          return true if File.new("/etc/exports", "r").gets(nil).include?(output)
          # @TODO: Add string to note that /etc/exports didn't need editing.
        rescue => err
          # @TODO: Add string to note that /etc/exports cannot be read.
        end
        false
      end


      # Render the output that will go into /etc/exports.
      #
      # @param [String] ip IP of the guest machine.
      # @param [Hash] folders Shared folders to sync.
      def render_nfs(ip, folders)
        Vagrant::Util::TemplateRenderer.render('nfs/exports',
                                               :uuid => env.vm.uuid,
                                               :ip => ip,
                                               :folders => folders)
      end

      # Exports the given hash of folders via NFS. This method will raise
      # an {Vagrant::Action::ActionException} if anything goes wrong.
      #
      # @param [String] output The rendered output of a template.
      def nfs_export(output)
      end

      # Cleans up the exports for the current VM.
      #
      # @param [String] output The rendered output of a template.
      def nfs_cleanup(output)
      end
    end
  end
end
