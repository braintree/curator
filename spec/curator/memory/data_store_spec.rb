require 'spec_helper'
require 'active_support/core_ext/numeric/time'
require 'active_support/core_ext/date/calculations'
require 'curator/memory/data_store'

module Curator::Memory
  describe Curator::Memory::DataStore do
    with_config do
      Curator.configure(:memory) do |config|
        config.environment = 'test'
      end
    end

    describe 'self.remove_all_keys' do
      it 'clears the data set' do
        DataStore._data[:foo] = 1
        DataStore.remove_all_keys
        DataStore._data.should == {}
      end
    end

    describe 'self.save' do
      it 'stores objects in an environment namespace' do
        DataStore.save(:collection_name => 'fake_things', :key => 'foo', :value => {'foo' => 1})
        DataStore._records('test:fake_things')['foo'].should == {'foo' => 1}
      end

      it 'updated objects in place' do
        DataStore.save(:collection_name => 'fake_things', :key => 'foo', :value => {'foo' => 1})
        DataStore.save(:collection_name => 'fake_things', :key => 'foo', :value => {'foo' => 2})
        DataStore.find_by_key('fake_things', 'foo').should == {:key => 'foo', :data => {'foo' => 2}}
      end

      it 'generates a new key if not provided' do
        DataStore.save(:collection_name => 'fake_things', :key => 'abc', :value => {'foo' => 1})
        DataStore.save(:collection_name => 'fake_things', :value => {'foo' => 2})
        DataStore.find_by_key('fake_things', 'abd').should == {:key => 'abd', :data => {'foo' => 2}}
      end

      it 'returns an object with a key' do
        object = DataStore.save(:collection_name => 'fake_things', :key => 'abc', :value => {'foo' => 1})
        object.should respond_to(:key)
      end
    end

    describe 'self.delete' do
      it 'deletes an object in a bucket for a key' do
        DataStore.save(:collection_name => 'heap', :key => 'some_key', :value => {'k' => 'v'})
        DataStore.delete('heap', 'some_key')
        DataStore.find_by_key('heap', 'some_key').should be_nil
      end

      it 'deletes indexes for the key' do
        DataStore.save(:collection_name => 'heap', :key => 'some_key', :value => {'k' => 'v'}, :index => {:k => 'v'})
        DataStore.delete('heap', 'some_key')
        DataStore.find_by_index('heap', :k, 'v').should be_empty
      end
    end

    describe 'self.find_by_key' do
      it 'returns nil when the key does not exist' do
        DataStore.find_by_key('fake_things', 'blah').should be_nil
      end

      it 'returns an object by key' do
        DataStore.save(:collection_name => 'fake_things', :key => 'foo', :value => {'foo' => 1})
        DataStore.find_by_key('fake_things', 'foo').should == {:key => 'foo', :data => {'foo' => 1}}
      end
    end

    describe 'self.find_by_index' do
      it 'returns an empty array if key is not found' do
        DataStore.find_by_index('abyss', 'invalid_index','invalid_key').should be_empty
      end

      it 'returns an empty array if key is nil' do
        DataStore.find_by_index('abyss', 'invalid_index', nil).should be_empty
      end

      it 'returns multiple objects' do
        DataStore.save(:collection_name => 'test_collection', :key => 'key1', :value => {:indexed_key => 'indexed_value'}, :index => {:indexed_key => 'indexed_value'})
        DataStore.save(:collection_name => 'test_collection', :key => 'key2', :value => {:indexed_key => 'indexed_value'}, :index => {:indexed_key => 'indexed_value'})

        keys = DataStore.find_by_index('test_collection', :indexed_key, 'indexed_value').map { |data| data[:key] }
        keys.sort.should == ['key1', 'key2']
      end

      it 'returns objects with an indexed number value in a range' do
        DataStore.save(:collection_name => 'test_collection', :key => 'key1', :value => {:indexed_key => 1}, :index => {:indexed_key => 1})
        DataStore.save(:collection_name => 'test_collection', :key => 'key2', :value => {:indexed_key => 5}, :index => {:indexed_key => 5})

        keys = DataStore.find_by_index('test_collection', :indexed_key, 0..2).map { |data| data[:key] }
        keys.sort.should == ['key1']
      end

      it 'returns objects with an index time value in a range' do
        DataStore.save(:collection_name => 'test_collection', :key => 'key1', :value => {:indexed_key => Time.now.utc}, :index => {:indexed_key => Time.now.utc})
        DataStore.save(:collection_name => 'test_collection', :key => 'key2', :value => {:indexed_key => 3.days.ago}, :index => {:indexed_key => 3.days.ago})

        range = (11.hours.from_now.utc..15.hours.from_now.utc)
        keys = DataStore.find_by_index('test_collection', :indexed_key, range).map { |data| data[:key] }
        keys.sort.should == []

        range = (15.minutes.ago.utc..5.minutes.from_now.utc)
        keys = DataStore.find_by_index('test_collection', :indexed_key, range).map { |data| data[:key] }
        keys.sort.should == ['key1']

        range = (10.days.ago.utc..4.days.from_now.utc)
        keys = DataStore.find_by_index('test_collection', :indexed_key, range).map { |data| data[:key] }
        keys.sort.should == ['key1', 'key2']
      end
    end
  end
end
