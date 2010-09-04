require 'fileutils'

module VagrantTestHelpers
  module Path
    # Path to the tmp directory for the tests
    def tmp_path
      Vagrant.source_root.join("test", "tmp")
    end

    # Path to the "home" directory for the tests
    def home_path
      tmp_path.join("home")
    end

    # Cleans all the test temp paths
    def clean_paths
      FileUtils.rm_rf(tmp_path)
      FileUtils.mkdir_p(tmp_path)
    end
  end
end
