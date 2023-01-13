require File.expand_path("../../../base", __FILE__)
require 'vagrant/util/file_mutex'

describe Vagrant::Util::FileMutex do
  include_context "unit"

  let(:temp_dir) { Dir.mktmpdir("vagrant-test-util-mutex_test") }

  after do
    FileUtils.rm_rf(temp_dir)
  end

  it "should create a lock file" do
    mutex_path = temp_dir + "test.lock"
    instance = described_class.new(mutex_path)
    instance.lock
    expect(File).to exist(mutex_path)
  end

  it "should create and delete lock file" do
    mutex_path = temp_dir + "test.lock"
    instance = described_class.new(mutex_path)
    instance.lock
    instance.unlock
    expect(File).to_not exist(mutex_path)
  end

  it "should not raise an error if the lock file does not exist" do
    mutex_path = temp_dir + "test.lock"
    instance = described_class.new(mutex_path)
    instance.unlock
    expect(File).to_not exist(mutex_path)
  end

  it "should run a function with a lock" do
    mutex_path = temp_dir + "test.lock"
    instance = described_class.new(mutex_path)
    instance.with_lock { true }
    expect(File).to_not exist(mutex_path)
  end

  it "should fail running a function when locked" do
    mutex_path = temp_dir + "test.lock"
    instance = described_class.new(mutex_path)
    instance.lock
    expect {instance.with_lock { true }}.
      to raise_error(Vagrant::Errors::VagrantLocked)
  end
end
