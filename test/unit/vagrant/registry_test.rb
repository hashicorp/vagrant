require File.expand_path('../../base', __FILE__)

describe Vagrant::Registry do
  let(:instance) { described_class.new }

  it 'should return nil for nonexistent items' do
    expect(instance.get('foo')).to be_nil
  end

  it 'should register a simple key/value' do
    instance.register('foo') { 'value' }
    expect(instance.get('foo')).to eq('value')
  end

  it 'should register an item without calling the block yet' do
    expect do
      instance.register('foo') do
        fail Exception, 'BOOM!'
      end
    end.to_not raise_error
  end

  it 'should raise an error if no block is given' do
    expect { instance.register('foo') }.
      to raise_error(ArgumentError)
  end

  it 'should call and return the result of a block when asking for the item' do
    object = Object.new
    instance.register('foo') do
      object
    end

    expect(instance.get('foo')).to eql(object)
  end

  it 'should be able to get the item with []' do
    object = Object.new
    instance.register('foo') { object }

    expect(instance['foo']).to eql(object)
  end

  it 'should be able to get keys with #keys' do
    instance.register('foo') { 'bar' }
    instance.register('baz') { fail 'BOOM' }

    expect(instance.keys.sort).to eq(%w(baz foo))
  end

  it 'should cache the result of the item so they can be modified' do
    # Make the proc generate a NEW array each time
    instance.register('foo') { [] }

    # Test that modifying the result modifies the actual cached
    # value. This verifies we're caching.
    expect(instance.get('foo')).to eq([])
    instance.get('foo') << 'value'
    expect(instance.get('foo')).to eq(['value'])
  end

  it 'should be able to check if a key exists' do
    instance.register('foo') { 'bar' }
    # expect(instance).to have_key("foo")
    expect(instance.keys).to eq(['foo'])
    expect(instance.get('bar')).to be_nil
    # expect(instance).not_to have_key("bar")
  end

  it 'should be enumerable' do
    instance.register('foo') { 'foovalue' }
    instance.register('bar') { 'barvalue' }

    keys   = []
    values = []
    instance.each do |key, value|
      keys << key
      values << value
    end

    expect(keys.sort).to eq(%w(bar foo))
    expect(values.sort).to eq(%w(barvalue foovalue))
  end

  it 'should be able to convert to a hash' do
    instance.register('foo') { 'foovalue' }
    instance.register('bar') { 'barvalue' }

    result = instance.to_hash
    expect(result).to be_a(Hash)
    expect(result['foo']).to eq('foovalue')
    expect(result['bar']).to eq('barvalue')
  end

  describe 'merging' do
    it 'should merge in another registry' do
      one = described_class.new
      two = described_class.new

      one.register('foo') { fail 'BOOM!' }
      two.register('bar') { fail 'BAM!' }

      three = one.merge(two)
      expect { three['foo'] }.to raise_error('BOOM!')
      expect { three['bar'] }.to raise_error('BAM!')
    end

    it 'should NOT merge in the cache' do
      one = described_class.new
      two = described_class.new

      one.register('foo') { [] }
      one['foo'] << 1

      two.register('bar') { [] }
      two['bar'] << 2

      three = one.merge(two)
      expect(three['foo']).to eq([])
      expect(three['bar']).to eq([])
    end
  end

  describe 'merge!' do
    it 'should merge into self' do
      one = described_class.new
      two = described_class.new

      one.register('foo') { 'foo' }
      two.register('bar') { 'bar' }

      one.merge!(two)
      expect(one['foo']).to eq('foo')
      expect(one['bar']).to eq('bar')
    end
  end
end
