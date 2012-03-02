require 'spec_helper'
require 'active_support/core_ext/numeric/time'
require 'active_support/core_ext/date/calculations'

Curator.configure(:mongo) do |config|
  config.environment = "test"
  config.database = "curator"
  config.mongo_config_file = File.expand_path(File.dirname(__FILE__) + "/../../../config/mongo.yml")
end

module Curator
  module Mongo
    describe Curator::Mongo::DataStore do
      before(:each) do
        DataStore.reset!
      end
      
      describe "self.client" do
        it "returns a mongo client with a config read from the yml file provided" do
          begin
            File.stub(:read).and_return(<<-YML)
            test:
              :host: localhost
              :port: 27017
            YML
            DataStore.instance_variable_set('@client', nil)
            client = DataStore.client
            client.host.should == 'localhost'
            client.port.should == 27017
          ensure
            DataStore.instance_variable_set("@client", nil)
          end
        end
      end

      describe "self.save" do
        it "namespaces collections with app and environment" do
          DataStore.save(collection_name: 'fake_things', key: 1, value: {foo: "bar"})
          DataStore.client.db(DataStore._db_name).collection('fake_things').find_one({'_id' => 1}).should == {"_id" => 1, "foo" => "bar"}
        end

        it 'updates objects in place' do
          DataStore.save(collection_name: 'fake_things', key: 'foo', value: {'foo' => 1})
          DataStore.save(collection_name: 'fake_things', key: 'foo', value: {'foo' => 2})
          DataStore.find_by_key('fake_things', 'foo').should == {key: 'foo', data: {'foo' => 2}}
        end

        it 'generates a new key if not provided' do
          DataStore.save(collection_name: 'fake_things', key: 'goonie', value: {foo: 1})
          id = DataStore.save(collection_name: 'fake_things',  value: {foo: 2})
          DataStore.find_by_key('fake_things', id[:key]).should == {:key => id[:key], :data => {'foo' => 2}}
        end
        
        it 'returns an object with a key' do
          object = DataStore.save(collection_name: 'fake_things', key: 'abc', value: {foo: 1})
          object.should respond_to :key
        end

        it "can index by multiple things" do
          begin
            DataStore.save(
                           collection_name: 'fake_things',
                           key: 'blah', value: {foo: 'foo-data', bar: 'bar-data'},
                           index: {foo: 1, bar: 1})
            foo_result = DataStore.find_by_index("fake_things", "foo", "foo-data").first
            foo_result[:key].should == 'blah'
            bar_result = DataStore.find_by_index("fake_things", "bar", "bar-data").first
            bar_result[:key].should == 'blah'
          ensure
            DataStore._collection("fake_things").remove(_id: "blah")
          end
        end
      end

      describe "self.delete" do
        it "deletes an object in a collection for a key" do
          DataStore.save(collection_name: 'heap', key: 10, value: {k: "v"})
          DataStore.delete("heap", 10)
          DataStore.find_by_key("heap", 10).should be_nil
        end
      end

      describe "find_by_index" do
        it "returns an empty array if key is not found" do
          DataStore.find_by_index("abyss", "invalid_index", "invalid_key").should be_empty
        end

        it "returns an empty array if key is nil" do
          DataStore.find_by_index("abyss", "invalid_index", nil).should be_empty
        end

        it "returns multiple objects" do
          DataStore.save(collection_name: 'test_collection', key: 10, value: {indexed_key: "indexed_value"}, index: {indexed_key: 'indexed_value'})
          DataStore.save(collection_name: 'test_collection', key: 11, value: {indexed_key: "indexed_value"}, index: {indexed_key: 'indexed_value'})
          keys = DataStore.find_by_index('test_collection', :indexed_key, 'indexed_value').map {|data| data[:key] }
          keys.map(&:to_s).sort.should == ['10', '11']
        end
      end

      describe "find_by_key" do
        it "returns an object by key" do
          DataStore.save(collection_name: "heap", key: 10, value: {k: "v"})
          DataStore.find_by_key("heap", 10).should == {:key => 10, :data => {'k' => 'v'}}
        end

        it 'returns nil when the key does not exist' do
          DataStore.find_by_key('heap', 300000000).should == nil
        end
      end

      context "collection name dependent on environment" do
        it "defaults collection name" do
          DataStore::_collection_name('my_collection').should == 'my_collection'
        end
      end
    end
  end
end
