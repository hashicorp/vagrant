require "test_helper"

class ConfigVMProvisionerTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Config::VMConfig::Provisioner
    @top = Vagrant::Config::Top.new(nil)
  end

  context "initializing" do
    should "expose the top instance that the provisioner belongs to" do
      instance = @klass.new(@top, :chef_solo)
      assert_equal @top, instance.top
    end

    should "expose the shortcut used" do
      instance = @klass.new(@top, :chef_solo)
      assert_equal :chef_solo, instance.shortcut
    end

    should "expose the provisioner class if its a valid shortcut" do
      instance = @klass.new(@top, :chef_solo)
      assert_equal Vagrant::Provisioners::ChefSolo, instance.provisioner
    end

    should "expose the provisioner class if its a valid class" do
      instance = @klass.new(@top, Vagrant::Provisioners::ChefSolo)
      assert_equal Vagrant::Provisioners::ChefSolo, instance.provisioner
    end

    should "have a nil provisioner class if invalid" do
      instance = @klass.new(@top, :i_shall_never_exist)
      assert_nil instance.provisioner
    end

    should "have a nil config instance if invalid" do
      instance = @klass.new(@top, :i_shall_never_exist)
      assert_nil instance.config
    end

    should "set the top of the config object to the given top" do
      instance = @klass.new(@top, :chef_solo)
      assert_equal @top, instance.config.top
    end

    should "configure the provisioner if valid" do
      instance = @klass.new(@top, :chef_solo) do |chef|
        chef.cookbooks_path = "foo"
      end

      assert_equal "foo", instance.config.cookbooks_path
    end

    should "configure the provisioner with a hash if valid" do
      instance = @klass.new(@top, :chef_solo, :cookbooks_path => "foo")
      assert_equal "foo", instance.config.cookbooks_path
    end
  end

  context "validation" do
    setup do
      @errors = Vagrant::Config::ErrorRecorder.new
    end

    should "be invalid if provisioner is valid" do
      instance = @klass.new(@top, :i_shall_never_exist)
      instance.validate(@errors)
      assert !@errors.errors.empty?
    end

    should "be invalid if provisioner doesn't inherit from provisioners base" do
      klass = Class.new
      instance = @klass.new(@top, klass)
      instance.validate(@errors)
      assert !@errors.errors.empty?
    end

    should "be valid with a valid provisioner" do
      instance = @klass.new(@top, :chef_solo) do |chef|
        chef.add_recipe "foo"
      end

      instance.validate(@errors)
      assert @errors.errors.empty?
    end

    should "be invalid if a provisioner's config is invalid" do
      instance = @klass.new(@top, :chef_solo)
      instance.validate(@errors)
      assert !@errors.errors.empty?
    end
  end
end
