module VagrantPlugins
  module HerokuPush
    module Errors
      class Error < Vagrant::Errors::VagrantError
        error_namespace("heroku_push.errors")
      end

      class CommandFailed < Error
        error_key(:command_failed)
      end

      class GitNotFound < Error
        error_key(:git_not_found)
      end

      class NotAGitRepo < Error
        error_key(:not_a_git_repo)
      end
    end
  end
end
