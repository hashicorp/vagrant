require "test_helper"

class ConfigSSHTest < Test::Unit::TestCase
  setup do
    @env = vagrant_env
  end

  should "expand any path when requesting the value" do
    result = File.expand_path(@env.config.ssh.private_key_path, @env.root_path)
    assert_equal result, @env.config.ssh.private_key_path
  end
end
