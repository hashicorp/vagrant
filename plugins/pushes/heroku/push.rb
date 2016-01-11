require "vagrant/util/subprocess"
require "vagrant/util/which"

require_relative "errors"

module VagrantPlugins
  module HerokuPush
    class Push < Vagrant.plugin("2", :push)
      def push
        # Expand any paths relative to the root
        dir = File.expand_path(config.dir, env.root_path)

        # Verify git is installed
        verify_git_bin!(config.git_bin)

        # Verify we are operating in a git repo
        verify_git_repo!(dir)

        # Get the current branch
        branch = git_branch(dir)

        # Get the name of the app
        app = config.app || interpret_app(dir)

        # Check if we need to add the git remote
        if !has_git_remote?(config.remote, dir)
          add_heroku_git_remote(config.remote, app, dir)
        end

        # Push to Heroku
        git_push_heroku(config.remote, branch, dir)
      end

      # Verify that git is installed.
      # @raise [Errors::GitNotFound]
      def verify_git_bin!(path)
        if Vagrant::Util::Which.which(path).nil?
          raise Errors::GitNotFound, bin: path
        end
      end

      # Verify that the given path is a git directory.
      # @raise [Errors::NotAGitRepo]
      # @param [String]
      def verify_git_repo!(path)
        if !File.directory?(git_dir(path))
          raise Errors::NotAGitRepo, path: path
        end
      end

      # Interpret the name of the Heroku application from the given path.
      # @param [String] path
      # @return [String]
      def interpret_app(path)
        File.basename(path)
      end

      # The git directory for the given path.
      # @param [String] path
      # @return [String]
      def git_dir(path)
        "#{path}/.git"
      end

      # The name of the current git branch.
      # @param [String] path
      # @return [String]
      def git_branch(path)
        result = execute!("git",
          "--git-dir", git_dir(path),
          "--work-tree", path,
          "symbolic-ref",
          "HEAD",
        )

        # Returns something like "* master"
        result.stdout.sub("*", "").strip
      end

      # Push to the Heroku remote.
      # @param [String] remote
      # @param [String] branch
      def git_push_heroku(remote, branch, path)
        execute!("git",
          "--git-dir", git_dir(path),
          "--work-tree", path,
          "push", remote, "#{branch}:master",
        )
      end

      # Check if the git remote has the given remote.
      # @param [String] remote
      # @return [true, false]
      def has_git_remote?(remote, path)
        result = execute!("git",
          "--git-dir", git_dir(path),
          "--work-tree", path,
          "remote",
        )
        remotes = result.stdout.split(/\r?\n/).map(&:strip)
        remotes.include?(remote.to_s)
      end

      # Add the Heroku to the current repository.
      # @param [String] remote
      # @param [String] app
      def add_heroku_git_remote(remote, app, path)
        execute!("git",
          "--git-dir", git_dir(path),
          "--work-tree", path,
          "remote", "add", remote, heroku_git_url(app),
        )
      end

      # The URL for this project on Heroku.
      # @return [String]
      def heroku_git_url(app)
        "git@heroku.com:#{app}.git"
      end

      # Execute the command, raising an exception if it fails.
      # @return [Vagrant::Util::Subprocess::Result]
      def execute!(*cmd)
        result = Vagrant::Util::Subprocess.execute(*cmd)

        if result.exit_code != 0
          raise Errors::CommandFailed,
            cmd:    cmd.join(" "),
            stdout: result.stdout,
            stderr: result.stderr
        end

        result
      end
    end
  end
end
