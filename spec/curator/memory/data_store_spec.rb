require 'spec_helper'
require 'active_support/core_ext/numeric/time'
require 'active_support/core_ext/date/calculations'
require 'curator/memory/data_store'
require 'curator/shared_data_store_specs'

module Curator::Memory
  describe Curator::Memory::DataStore do
    include_examples "data_store", DataStore

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
    end

    describe 'self.delete' do
      it 'deletes indexes for the key' do
        DataStore.save(:collection_name => 'heap', :key => 'some_key', :value => {'k' => 'v'}, :index => {:k => 'v'})
        DataStore.delete('heap', 'some_key')
        DataStore.find_by_index('heap', :k, 'v').should be_empty
      end
    end

    describe 'self.find_by_index' do
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
