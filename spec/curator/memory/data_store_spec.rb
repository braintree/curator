require 'spec_helper'
require 'active_support/core_ext/numeric/time'
require 'active_support/core_ext/date/calculations'
require 'curator/memory/data_store'
require 'curator/shared_data_store_specs'

module Curator::Memory
  describe Curator::Memory::DataStore do
    include_examples "data_store", DataStore

    let(:data_store) { DataStore.new }

    with_config do
      Curator.configure(:memory) do |config|
        config.environment = 'test'
      end
    end

    describe 'self.remove_all_keys' do
      it 'clears the data set' do
        data_store._data[:foo] = 1
        data_store.remove_all_keys
        data_store._data.should == {}
      end
    end

    describe 'self.save' do
      it 'stores objects in an environment namespace' do
        data_store.save(:collection_name => 'fake_things', :key => 'foo', :value => {'foo' => 1})
        data_store._records('test:fake_things')['foo'].should == {'foo' => 1}
      end
    end

    describe 'self.delete' do
      it 'deletes indexes for the key' do
        data_store.save(:collection_name => 'heap', :key => 'some_key', :value => {'k' => 'v'}, :index => {:k => 'v'})
        data_store.delete('heap', 'some_key')
        data_store.find_by_attribute('heap', :k, 'v').should be_empty
      end
    end

    describe 'self.find_by_attribute' do
      it 'returns objects with an indexed number value in a range' do
        data_store.save(:collection_name => 'test_collection', :key => 'key1', :value => {:indexed_key => 1}, :index => {:indexed_key => 1})
        data_store.save(:collection_name => 'test_collection', :key => 'key2', :value => {:indexed_key => 5}, :index => {:indexed_key => 5})

        keys = data_store.find_by_attribute('test_collection', :indexed_key, 0..2).map { |data| data[:key] }
        keys.sort.should == ['key1']
      end

      it 'returns objects with an index time value in a range' do
        data_store.save(:collection_name => 'test_collection', :key => 'key1', :value => {:indexed_key => Time.now.utc}, :index => {:indexed_key => Time.now.utc})
        data_store.save(:collection_name => 'test_collection', :key => 'key2', :value => {:indexed_key => 3.days.ago}, :index => {:indexed_key => 3.days.ago})

        range = (11.hours.from_now.utc..15.hours.from_now.utc)
        keys = data_store.find_by_attribute('test_collection', :indexed_key, range).map { |data| data[:key] }
        keys.sort.should == []

        range = (15.minutes.ago.utc..5.minutes.from_now.utc)
        keys = data_store.find_by_attribute('test_collection', :indexed_key, range).map { |data| data[:key] }
        keys.sort.should == ['key1']

        range = (10.days.ago.utc..4.days.from_now.utc)
        keys = data_store.find_by_attribute('test_collection', :indexed_key, range).map { |data| data[:key] }
        keys.sort.should == ['key1', 'key2']
      end
    end
  end
end
