require File.join(File.dirname(__FILE__), '..', '..', '..', 'test_helper')


class CheckVMActionTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action::VM::Check
    @app, @env = mock_action_data
    @instance = @klass.new(@app, @env)
    
    @env['config'].vm.box = "foo"
  end 
  should "check if the box exist" do
    Vagrant::Box.expects("find").with(@env.env, 'foo')
    @instance.call(@env)
  end 

  
  should 'continue the chain process' do
    Vagrant::Box.stubs('find').with(@env.env, 'foo')
    @app.expects(:call).with(@env).once
    @instance.call(@env)
  end   
  
end 

