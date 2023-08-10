# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

require File.expand_path("../../../base", __FILE__)
require 'vagrant/util/file_mutex'

describe Vagrant::Util::FileMutex do
  include_context "unit"

  let(:temp_dir) { Dir.mktmpdir("vagrant-test-util-mutex_test") }
  let(:mutex_path) { File.join(temp_dir, "test.lock") }
  let(:subject) { described_class.new(mutex_path) }

  after do
    FileUtils.rm_rf(temp_dir)
  end

  it "should create a lock file" do
    subject.lock
    expect(File).to exist(mutex_path)
  end

  it "should create and delete lock file" do
    subject.lock
    expect(File).to exist(mutex_path)
    subject.unlock
    expect(File).to_not exist(mutex_path)
  end

  it "should not raise an error if the lock file does not exist" do
    subject.unlock
    expect(File).to_not exist(mutex_path)
  end

  it "should run a function with a lock" do
    subject.with_lock { true }
    expect(File).to_not exist(mutex_path)
  end

  it "should fail running a function when locked" do
    # create a lock
    subject.lock
    # create a new lock that will run a function
    instance = described_class.new(mutex_path)
    # lock should persist for multiple runs
    expect {instance.with_lock { true }}.
      to raise_error(Vagrant::Errors::VagrantLocked)
    expect {instance.with_lock { true }}.
      to raise_error(Vagrant::Errors::VagrantLocked)
    # mutex should exist until its unlocked
    expect(File).to exist(mutex_path)
    subject.unlock
    expect(File).to_not exist(mutex_path)
  end

  it "should fail running a function within a locked" do
    # create a new lock that will run a function
    instance = described_class.new(mutex_path)
    expect {
      subject.with_lock { instance.with_lock{true} }
    }.to raise_error(Vagrant::Errors::VagrantLocked)
    expect(File).to_not exist(mutex_path)
  end

  it "should delete the lock even when the function fails" do
    expect {
      subject.with_lock { raise Vagrant::Errors::VagrantError.new }
    }.to raise_error(Vagrant::Errors::VagrantError)
    expect(File).to_not exist(mutex_path)
  end

  it "should unlock file before deletion" do
    lock_file = double(:lock_file)
    allow(subject).to receive(:lock_file).and_return(lock_file)
    allow(lock_file).to receive(:flock).and_return(true)

    expect(lock_file).to receive(:flock).with(File::LOCK_UN)
    expect(lock_file).to receive(:close)

    subject.with_lock { true }
  end
end
