require "test_helper"

class BoxCollectionTest < Test::Unit::TestCase
  setup do
    clean_paths

    @klass = Vagrant::BoxCollection
  end

  should "load all the boxes from the box path" do
    vagrant_box("foo")
    vagrant_box("bar")

    result = @klass.new(vagrant_env)
    names = result.collect { |b| b.name }.sort
    assert_equal 2, result.length
    assert_equal ["bar", "foo"], names
  end

  should "reload the box list" do
    instance = @klass.new(vagrant_env)
    assert instance.empty?

    vagrant_box("foo")

    instance.reload!
    assert !instance.empty?
  end

  should "find a specific box" do
    vagrant_box("foo")
    vagrant_box("bar")

    instance = @klass.new(vagrant_env)
    result = instance.find("foo")
    assert result
    assert_equal "foo", result.name
  end

  should "return nil if it couldn't find a specific box" do
    instance = @klass.new(vagrant_env)
    assert_nil instance.find("thisshouldnotexist")
  end
end
