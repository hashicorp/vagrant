require "test_helper"

class CommandInitCommandTest < Test::Unit::TestCase
  should "create a Vagrantfile in the environment's cwd" do
    path = vagrant_app
    env = Vagrant::Environment.new(:cwd => path)
    silence(:stdout) { env.cli("init") }
    assert File.exist?(path.join("Vagrantfile"))
  end
end
