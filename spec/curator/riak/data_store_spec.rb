require 'spec_helper'
require 'curator/shared_data_store_specs'

module Curator
  module Riak
    describe Curator::Riak::DataStore do
      include_examples "data_store"

      let(:data_store) { DataStore.new }

      context "collection settings" do
        it "returns settings" do
          bucket_props = data_store.settings("test_bucket")
          bucket_props.keys.should_not be_empty
        end

        it "sets updated settings" do
          bucket_props = data_store.settings("test_bucket")
          expected = !bucket_props["allow_mult"]
          new_props = {"allow_mult" => expected}
          data_store.update_settings!("test_bucket", new_props)

          data_store.settings("test_bucket").should include("allow_mult" => expected)
        end
      end

      describe "self.client" do
        context "with a client manually configured" do
          with_config do
            Curator.configure(:resettable_riak) do |config|
              config.environment = "test"
              config.client      = ::Riak::Client.new
            end
          end

          it "should return the client and not use the yaml file" do
            data_store.client.should == Curator.config.client
          end
        end

        it "returns a riak client with a config read from the yml file provided" do
          begin
            File.should_receive(:read).and_return(<<-YML)
            test:
              :host: somehost
              :http_port: 1234
              :pb_port: 5678
            YML
            data_store.instance_variable_set('@client', nil)
            client = data_store.client
            client.node.host.should == "somehost"
            client.node.http_port.should == 1234
            client.node.pb_port.should == 5678
          ensure
            data_store.instance_variable_set("@client", nil)
          end
        end
      end

      describe "self.save" do
        it "namespaces buckets with app and environment" do
          data_store.save(:collection_name => "fake_things", :key => "blah", :value => {"foo" => "bar"})
          data_store.client.bucket(data_store._bucket_name("fake_things")).get("blah").data.should == {"foo" => "bar"}
        end

        it "sets content_type for serialization with an option" do
          begin
            data_store.save(
              :collection_name => "fake_things",
              :key => "key",
              :value => "i am plain text",
              :content_type => "text/plain"
            )

            result = data_store.find_by_key("fake_things", "key")
            result[:data].should == "i am plain text"
          ensure
            data_store._bucket("fake_things").delete("blah")
          end
        end
      end

      context "bucket name dependent on environment" do
        it "defaults bucket name" do
          data_store::_bucket_name("my_bucket").should == "#{Curator.config.bucket_prefix}:test:my_bucket"
        end
      end

      describe "Riak.escaper hardwiring to CGI is backward compatible with Riak client default setting" do
        after :all do
          ::Riak.escaper = CGI
        end

        it "can read data with CGI escaper that was written with URI escaper" do
          ::Riak.escaper = URI
          data_store.save(:collection_name => "fake_things", :key => "some_key", :value => {"k" => "v"})
          ::Riak.escaper = CGI
          data_store.find_by_key("fake_things", "some_key").should == {:key => "some_key", :data => {"k" => "v"}}
        end

        it "can read data with URI escaper that was written with CGI escaper" do
          ::Riak.escaper = CGI
          data_store.save(:collection_name => "fake_things", :key => "some_key", :value => {"k" => "v"})
          ::Riak.escaper = URI
          data_store.find_by_key("fake_things", "some_key").should == {:key => "some_key", :data => {"k" => "v"}}
        end
      end
    end
  end
end
