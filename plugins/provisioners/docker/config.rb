require 'set'

module VagrantPlugins
  module Docker
    class Config < Vagrant.plugin("2", :config)
      attr_reader :build_images, :images, :containers, :build_options
      attr_accessor :version

      def initialize
        @images         = Set.new
        @containers     = Hash.new
        @version        = UNSET_VALUE
        @build_images   = []
      end

      # Defines an image to build using `docker build` within the machine.
      #
      # @param [String] path Path to the Dockerfile to pass to
      #   `docker build`.
      def build_image(path, **opts)
        @build_images << [path, opts]
      end

      def images=(images)
        @images = Set.new(images)
      end

      def pull_images(*images)
        @images += images.map(&:to_s)
      end

      def run(name, **options)
        params = options.dup
        params[:image] ||= name
        params[:daemonize] = true if !params.has_key?(:daemonize)

        # TODO: Validate provided parameters before assignment
        @containers[name.to_s] = params
      end

      def finalize!
        @version = "latest" if @version == UNSET_VALUE
        @version = @version.to_sym
      end

      def merge(other)
        super.tap do |result|
          result.pull_images(*(other.images + self.images))
        end
      end
    end
  end
end
