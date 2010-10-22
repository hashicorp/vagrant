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
    assert result.length >= 2
    assert names.include?("foo")
    assert names.include?("bar")
  end

  should "reload the box list" do
    instance = @klass.new(vagrant_env)
    amount = instance.length

    vagrant_box("foo")

    instance.reload!
    assert_equal (amount + 1), instance.length
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
