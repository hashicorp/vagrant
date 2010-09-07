module Vagrant
  module Util
    # This class just contains some platform checking code.
    class Platform
      class << self
        def tiger?
          platform.include?("darwin8")
        end

        def leopard?
          platform.include?("darwin9")
        end

        [:darwin, :bsd, :linux].each do |type|
          define_method("#{type}?") do
            platform.include?(type.to_s)
          end
        end

        def windows?
          %W[mingw mswin].each do |text|
            return true if platform.include?(text)
          end

          false
        end

        def tar_file_options
          # create, write only, fail if the file exists, binary if windows
          File::WRONLY|File::EXCL|File::CREAT|(Mario::Platform.windows? ? File::BINARY : 0)
        end

        def platform
          RUBY_PLATFORM.to_s.downcase
        end
      end
    end
  end
end
