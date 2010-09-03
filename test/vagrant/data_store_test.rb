require "test_helper"

class DataStoreTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::DataStore
    @initial_data = { "foo" => "bar" }
    @db_file = File.expand_path("test/tmp/data_store_test", Vagrant.source_root)
    File.open(@db_file, "w") { |f| f.write(@initial_data.to_json) }

    @instance = @klass.new(@db_file)
  end

  teardown do
    File.delete(@db_file) if File.file?(@db_file)
  end

  should "be a hash with indifferent access" do
    assert @instance.is_a?(Vagrant::Util::HashWithIndifferentAccess)
  end

  should "just be an empty hash if file doesn't exist" do
    assert @klass.new("NEvERNENVENRNE").empty?
  end

  should "read the data" do
    assert_equal @initial_data["foo"], @instance[:foo]
  end

  should "write the data, but not save it right away" do
    @instance[:foo] = "changed"
    assert_equal "changed", @instance[:foo]
    assert_equal @initial_data["foo"], @klass.new(@db_file)["foo"]
  end

  should "write the data if commit is called" do
    @instance[:foo] = "changed"
    @instance.commit

    assert_equal "changed", @klass.new(@db_file)[:foo]
  end

  should "delete the data store file if the hash is empty" do
    @instance[:foo] = :bar
    @instance.commit
    assert File.exist?(@db_file)

    @instance.clear
    assert @instance.empty?
    @instance.commit
    assert !File.exist?(@db_file)
  end

  should "clean nil and empties if commit is called" do
    @instance[:foo] = { :bar => nil }
    @instance[:bar] = {}
    @instance.commit

    assert !@instance.has_key?(:foo)
    assert !@instance.has_key?(:bar)
  end
end
