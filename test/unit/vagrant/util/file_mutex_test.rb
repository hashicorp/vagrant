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
    expect(File).to exist(mutex_path)
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
    # create a lock
    instance = described_class.new(mutex_path)
    instance.lock
    # create a new lock that will run a function
    instance2 = described_class.new(mutex_path)
    # lock should persist for multiple runs
    expect {instance2.with_lock { true }}.
      to raise_error(Vagrant::Errors::VagrantLocked)
    expect {instance2.with_lock { true }}.
      to raise_error(Vagrant::Errors::VagrantLocked)
    # mutex should exist until its unlocked
    expect(File).to exist(mutex_path)
    instance.unlock
    expect(File).to_not exist(mutex_path)
  end

  it "should fail running a function within a locked" do
    mutex_path = temp_dir + "test.lock"
    # create a lock
    instance = described_class.new(mutex_path)
    # create a new lock that will run a function
    instance2 = described_class.new(mutex_path)
    expect {
      instance.with_lock { instance2.with_lock{true} }
    }.to raise_error(Vagrant::Errors::VagrantLocked)
    expect(File).to_not exist(mutex_path)
  end

  it "should delete the lock even when the function fails" do
    mutex_path = temp_dir + "test.lock"
    instance = described_class.new(mutex_path)
    expect {
      instance.with_lock { raise Vagrant::Errors::VagrantError.new }
    }.to raise_error(Vagrant::Errors::VagrantError)
    expect(File).to_not exist(mutex_path)
  end
end
