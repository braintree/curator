require 'spec_helper'

describe Riak::DataStore do
  describe "self.client" do
    it "returns a riak client with a config read from the yml file provided" do
      begin
        File.should_receive(:read).and_return(<<-YML)
        test:
          :host: somehost
          :http_port: 1234
          :pb_port: 5678
        YML
        Riak::DataStore.instance_variable_set('@client', nil)
        client = Riak::DataStore.client
        client.node.host.should == "somehost"
        client.node.http_port.should == 1234
        client.node.pb_port.should == 5678
      ensure
        Riak::DataStore.instance_variable_set("@client", nil)
      end
    end
  end

  describe "self.save" do
    it "namespaces buckets with app and environment" do
      Riak::DataStore.save(:collection_name => "fake_things", :key => "blah", :value => {"foo" => "bar"})
      Riak::DataStore.client.bucket(Riak::DataStore._bucket_name("fake_things")).get("blah").data.should == {"foo" => "bar"}
    end

    it "can index by multiple things" do
      begin
        Riak::DataStore.save(
          :collection_name => "fake_things",
          :key => "blah",
          :value => {:foo => "foo-data", :bar => "bar-data"},
          :index => {:foo => "foo-data", :bar => "bar-data"}
        )

        foo_result = Riak::DataStore.find_by_index("fake_things", "foo", "foo-data").first
        foo_result[:key].should == "blah"
        bar_result = Riak::DataStore.find_by_index("fake_things", "bar", "bar-data").first
        bar_result[:key].should == "blah"
      ensure
        Riak::DataStore._bucket("fake_things").delete("blah")
      end
    end
  end

  describe "self.delete" do
    it "deletes an object in a buket for a key" do
      Riak::DataStore.save(:collection_name => "heap", :key => "some_key", :value => {"k" => "v"})
      Riak::DataStore.delete("heap", "some_key")
      Riak::DataStore.find_by_key("heap", "some_key").should be_nil
    end
  end

  describe "find_by_index" do
    it "returns an empty array if key is not found" do
      Riak::DataStore.find_by_index("abyss","invalid_index","invalid_key").should be_empty
    end

    it "returns an empty array if key is nil" do
      Riak::DataStore.find_by_index("abyss","invalid_index", nil).should be_empty
    end

    it "returns multiple objects" do
      Riak::DataStore.save(:collection_name => "test_collection", :key => "key1", :value => {:indexed_key => "indexed_value"}, :index => {:indexed_key => "indexed_value"})
      Riak::DataStore.save(:collection_name => "test_collection", :key => "key2", :value => {:indexed_key => "indexed_value"}, :index => {:indexed_key => "indexed_value"})

      keys = Riak::DataStore.find_by_index("test_collection", :indexed_key, "indexed_value").map { |data| data[:key] }
      keys.sort.should == ["key1", "key2"]
    end
  end

  describe "find_by_key" do
    it "returns an object by key" do
      Riak::DataStore.save(:collection_name => "heap", :key => "some_key", :value => {"k" => "v"})
      Riak::DataStore.find_by_key("heap", "some_key").should == {:key => "some_key", :data => {"k" => "v"}}
    end
  end

  context "bucket name dependent on environment" do
    it "defaults bucket name" do
      Riak::DataStore::_bucket_name("my_bucket").should == "#{Curator.bucket_prefix}:test:my_bucket"
    end
  end
end
