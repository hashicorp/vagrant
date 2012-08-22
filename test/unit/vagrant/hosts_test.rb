require File.expand_path("../../base", __FILE__)

describe Vagrant::Hosts do
  let(:registry) { Hash.new }
  let(:base_class) { Vagrant::Plugin::V1::Host }

  it "detects the host that matches true" do
    foo_klass = Class.new(base_class) do
      def self.match?; false; end
    end

    bar_klass = Class.new(base_class) do
      def self.match?; true; end
    end

    registry[:foo] = foo_klass
    registry[:bar] = bar_klass

    described_class.detect(registry).should == bar_klass
  end

  it "detects the host that matches true with the highest precedence first" do
    foo_klass = Class.new(base_class) do
      def self.match?; true; end
    end

    bar_klass = Class.new(base_class) do
      def self.match?; true; end
      def self.precedence; 9; end
    end

    registry[:foo] = foo_klass
    registry[:bar] = bar_klass

    described_class.detect(registry).should == bar_klass
  end
end
