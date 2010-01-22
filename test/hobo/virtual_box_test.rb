require File.join(File.dirname(__FILE__), '..', 'test_helper')

class VirtualBoxTest < Test::Unit::TestCase  
  setup do
    # Stub out command so nothing actually happens
    VirtualBox.stubs(:command)
  end
  
  context "parsing key value pairs" do
    should "not parse the lines which don't contain key value pairs" do
      result = VirtualBox.parse_kv_pairs("I'm not a key value pair")
      assert result.empty?
    end
    
    should "parse the lines which contain key value pairs" do
      result = VirtualBox.parse_kv_pairs("foo=bar")
      assert_equal 1, result.length
      assert_equal "bar", result["foo"]
    end
    
    should "ignore surrounding double quotes on keys and values" do
      result = VirtualBox.parse_kv_pairs('"foo"="a value"')
      assert_equal 1, result.length
      assert_equal "a value", result["foo"]
    end
    
    should "trim the values" do
      result = VirtualBox.parse_kv_pairs("foo=bar        ")
      assert_equal 1, result.length
      assert_equal "bar", result["foo"]
    end
    
    should "parse multiple lines" do
      result = VirtualBox.parse_kv_pairs(<<-raw)
This is some header

foo=bar
"bar"=baz
raw

      assert_equal 2, result.length
      assert_equal "bar", result["foo"]
      assert_equal "baz", result["bar"]
    end
  end
end