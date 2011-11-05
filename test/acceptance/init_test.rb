require File.expand_path("../base", __FILE__)

class InitTest < AcceptanceTest
  should "create a Vagrantfile in the working directory" do
    vagrantfile = @environment.workdir.join("Vagrantfile")
    assert(!vagrantfile.exist?, "Vagrantfile shouldn't exist")

    result = execute("vagrant", "init")
    assert(result.success?, "init should succeed")
    assert(vagrantfile.exist?, "Vagrantfile should exist")
  end

  should "create a Vagrantfile with the box set to the given argument" do
    vagrantfile = @environment.workdir.join("Vagrantfile")

    result = execute("vagrant", "init", "foo")
    assert(result.success?, "init should succeed")
    assert(vagrantfile.read =~ /config.vm.box = "foo"$/,
           "config.vm.box should be set to 'foo'")
  end

  should "create a Vagrantfile with the box URL set to the given argument" do
    vagrantfile = @environment.workdir.join("Vagrantfile")

    result = execute("vagrant", "init", "foo", "bar")
    assert(result.success?, "init should succeed")

    contents = vagrantfile.read
    assert(contents =~ /config.vm.box = "foo"$/,
           "config.vm.box should be set to 'foo'")
    assert(contents =~ /config.vm.box_url = "bar"$/,
           "config.vm.box_url should be set to 'bar'")
  end
end
