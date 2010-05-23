module Vagrant
  module Util
    # This class just contains some platform checking code.
    class Platform
      class << self
        def leopard?
          RUBY_PLATFORM.downcase.include?("darwin9")
        end

        def tar_file_options
          # create, write only, fail if the file exists, binary if windows
          File::WRONLY|File::EXCL|File::CREAT|(Mario::Platform.windows? ? File::BINARY : 0)
        end
      end
    end
  end
end
