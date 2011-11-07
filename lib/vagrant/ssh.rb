require 'aruba/api'
require 'vagrant/helpers/ssh'

$stdout.sync=true if not $stdout.sync
$stderr.sync=true if not $stderr.sync

module Vagrant
  # Manages SSH access to a specific environment. Allows an environment to
  # replace the process with SSH itself, run a specific set of commands,
  # upload files, or even check if a host is up.
  class SSH
    # Inorder to utilize Aruba assertions about exit status and success.
    require 'rspec/expectations'
    include RSpec::Matchers

    include Util::Retryable
    include Util::SafeExec
    include ::Aruba::Api
    include ::Vagrant::Helpers::Ssh

    # Reference back up to the environment which this SSH object belongs to
    attr_accessor :env
    attr_reader :session

    def initialize(environment)
      @env = environment
      @current_session = nil
    end
  end
end
