require 'spec_helper'

module Curator
  module Riak
    describe Curator::Riak::DataStore do
      describe "self.client" do
        it "returns a riak client with a config read from the yml file provided" do
          begin
            File.should_receive(:read).and_return(<<-YML)
            test:
              :host: somehost
              :http_port: 1234
              :pb_port: 5678
            YML
            DataStore.instance_variable_set('@client', nil)
            client = DataStore.client
            client.node.host.should == "somehost"
            client.node.http_port.should == 1234
            client.node.pb_port.should == 5678
          ensure
            DataStore.instance_variable_set("@client", nil)
          end
        end
      end

      describe "self.save" do
        it "namespaces buckets with app and environment" do
          DataStore.save(:collection_name => "fake_things", :key => "blah", :value => {"foo" => "bar"})
          DataStore.client.bucket(DataStore._bucket_name("fake_things")).get("blah").data.should == {"foo" => "bar"}
        end

        it "can index by multiple things" do
          begin
            DataStore.save(
              :collection_name => "fake_things",
              :key => "blah",
              :value => {:foo => "foo-data", :bar => "bar-data"},
              :index => {:foo => "foo-data", :bar => "bar-data"}
            )

            foo_result = DataStore.find_by_index("fake_things", "foo", "foo-data").first
            foo_result[:key].should == "blah"
            bar_result = DataStore.find_by_index("fake_things", "bar", "bar-data").first
            bar_result[:key].should == "blah"
          ensure
            DataStore._bucket("fake_things").delete("blah")
          end
        end

        it "sets content_type for serialization with an option" do
          begin
            DataStore.save(
              :collection_name => "fake_things",
              :key => "key",
              :value => "i am plain text",
              :content_type => "text/plain"
            )

            result = DataStore.find_by_key("fake_things", "key")
            result[:data].should == "i am plain text"
          ensure
            DataStore._bucket("fake_things").delete("blah")
          end
        end
      end

      describe "self.delete" do
        it "deletes an object in a buket for a key" do
          DataStore.save(:collection_name => "heap", :key => "some_key", :value => {"k" => "v"})
          DataStore.delete("heap", "some_key")
          DataStore.find_by_key("heap", "some_key").should be_nil
        end
      end

      describe "find_by_index" do
        it "returns an empty array if key is not found" do
          DataStore.find_by_index("abyss","invalid_index","invalid_key").should be_empty
        end

        it "returns an empty array if key is nil" do
          DataStore.find_by_index("abyss","invalid_index", nil).should be_empty
        end

        it "returns multiple objects" do
          DataStore.save(:collection_name => "test_collection", :key => "key1", :value => {:indexed_key => "indexed_value"}, :index => {:indexed_key => "indexed_value"})
          DataStore.save(:collection_name => "test_collection", :key => "key2", :value => {:indexed_key => "indexed_value"}, :index => {:indexed_key => "indexed_value"})

          keys = DataStore.find_by_index("test_collection", :indexed_key, "indexed_value").map { |data| data[:key] }
          keys.sort.should == ["key1", "key2"]
        end
      end

      describe "find_by_key" do
        it "returns nil when the key does not exist" do
          DataStore.find_by_key("heap", "some_key").should be_nil
        end

        it "returns an object by key" do
          DataStore.save(:collection_name => "heap", :key => "some_key", :value => {"k" => "v"})
          DataStore.find_by_key("heap", "some_key").should == {:key => "some_key", :data => {"k" => "v"}}
        end
      end

      context "bucket name dependent on environment" do
        it "defaults bucket name" do
          DataStore::_bucket_name("my_bucket").should == "#{Curator.config.bucket_prefix}:test:my_bucket"
        end
      end
    end
  end
end
