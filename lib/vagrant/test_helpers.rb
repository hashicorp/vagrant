module Vagrant
  module TestHelpers
    #------------------------------------------------------------
    # Environment creation helpers
    #------------------------------------------------------------
    # Creates a "vagrant_app" directory in the test tmp folder
    # which can be used for creating test Vagrant environments.
    # Returns the root directory of the app.
    def vagrant_app(*path)
      root = tmp_path.join("vagrant_app")
      FileUtils.rm_rf(root)
      FileUtils.mkdir_p(root)
      root.join(*path)
    end

    # Creates a Vagrantfile with the given contents in the given
    # app directory.
    def vagrantfile(*args)
      path = args.shift.join("Vagrantfile") if Pathname === args.first
      path ||= vagrant_app("Vagrantfile")
      str  = args.shift || ""
      File.open(path.to_s, "w") do |f|
        f.puts "Vagrant::Config.run do |config|"
        f.puts "config.vagrant.home = '#{home_path}'"
        f.puts str
        f.puts "end"
      end

      path.parent
    end

    # Creates and _loads_ a Vagrant environment at the given path
    def vagrant_env(*args)
      path = args.shift if Pathname === args.first
      path ||= vagrantfile
      Vagrant::Environment.new(:cwd => path).load!
    end

    # Creates the folder to contain a vagrant box
    def vagrant_box(name)
      result = boxes_path.join(name)
      FileUtils.mkdir_p(result)
      result
    end

    # Returns a blank app (callable) and action environment with the
    # given vagrant environment.
    def action_env(v_env = nil)
      v_env ||= vagrant_env
      app = lambda { |env| }
      env = Vagrant::Action::Environment.new(v_env)
      env["vagrant.test"] = true
      [app, env]
    end

    #------------------------------------------------------------
    # Path helpers
    #------------------------------------------------------------
    # Path to the tmp directory for the tests
    def tmp_path
      result = Vagrant.source_root.join("test", "tmp")
      FileUtils.mkdir_p(result)
      result
    end

    # Path to the "home" directory for the tests
    def home_path
      result = tmp_path.join("home")
      FileUtils.mkdir_p(result)
      result
    end

    # Path to the boxes directory in the home directory
    def boxes_path
      result = home_path.join("boxes")
      FileUtils.mkdir_p(result)
      result
    end

    # Cleans all the test temp paths
    def clean_paths
      FileUtils.rm_rf(tmp_path)

      # Call these methods only to rebuild the directories
      tmp_path
      home_path
      boxes_path
    end
  end
end
