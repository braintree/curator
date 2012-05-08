require 'spec_helper'
require 'curator/shared_data_store_specs'

module Curator
  module Riak
    describe Curator::Riak::DataStore do
      include_examples "data_store", DataStore

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

      context "bucket name dependent on environment" do
        it "defaults bucket name" do
          DataStore::_bucket_name("my_bucket").should == "#{Curator.config.bucket_prefix}:test:my_bucket"
        end
      end

      describe "Riak.escaper hardwiring to CGI is backward compatible with Riak client default setting" do
        after :all do
          ::Riak.escaper = CGI
        end

        it "can read data with CGI escaper that was written with URI escaper" do
          ::Riak.escaper = URI
          DataStore.save(:collection_name => "fake_things", :key => "some_key", :value => {"k" => "v"})
          ::Riak.escaper = CGI
          DataStore.find_by_key("fake_things", "some_key").should == {:key => "some_key", :data => {"k" => "v"}}
        end

        it "can read data with URI escaper that was written with CGI escaper" do
          ::Riak.escaper = CGI
          DataStore.save(:collection_name => "fake_things", :key => "some_key", :value => {"k" => "v"})
          ::Riak.escaper = URI
          DataStore.find_by_key("fake_things", "some_key").should == {:key => "some_key", :data => {"k" => "v"}}
        end
      end
    end
  end
end
