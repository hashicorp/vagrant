module VagrantTestHelpers
  module Path
    # Path to the tmp directory for the tests
    def tmp_path
      Vagrant.source_root.join("test", "tmp")
    end
  end
end
