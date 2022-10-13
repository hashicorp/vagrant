require 'set'

module VagrantPlugins
  module ContainerProvisioner
    class Config < Vagrant.plugin("2", :config)
      attr_reader :images
      attr_accessor :post_install_provisioner

      def initialize
        @images = Set.new
        @post_install_provisioner = nil

        @__build_images   = []
        @__containers     = Hash.new { |h, k| h[k] = {} }
      end

      # Accessor for internal state.
      def build_images
        @__build_images
      end

      # Accessor for the internal state.
      def containers
        @__containers
      end

      # Defines an image to build using `<cmd> build` within the machine.
      #
      # @param [String] path Path to the Dockerfile to pass to
      #   container build command
      def build_image(path, **opts)
        @__build_images << [path, opts]
      end

      def images=(images)
        @images = Set.new(images)
      end

      def pull_images(*images)
        @images += images.map(&:to_s)
      end

      def post_install_provision(name, **options, &block)
        proxy = VagrantPlugins::Kernel_V2::VMConfig.new
        proxy.provision(name, **options, &block)
        @post_install_provisioner = proxy.provisioners.first
      end

      def run(name, **options)
        @__containers[name.to_s] = options.dup
      end

      def merge(other)
        super.tap do |result|
          result.pull_images(*(other.images + self.images))

          build_images = @__build_images.dup
          build_images += other.build_images
          result.instance_variable_set(:@__build_images, build_images)

          containers = {}
          @__containers.each do |name, params|
            containers[name] = params.dup
          end
          other.containers.each do |name, params|
            containers[name] = @__containers[name].merge(params)
          end

          result.instance_variable_set(:@__containers, containers)
        end
      end

      def finalize!
        @__containers.each do |name, params|
          params[:image] ||= name
          params[:auto_assign_name] = true if !params.key?(:auto_assign_name)
          params[:daemonize] = true if !params.key?(:daemonize)
          params[:restart] = "always" if !params.key?(:restart)
        end
      end
    end
  end
end
