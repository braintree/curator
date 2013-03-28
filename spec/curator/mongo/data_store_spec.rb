require 'spec_helper'
require 'active_support/core_ext/numeric/time'
require 'active_support/core_ext/date/calculations'
require 'curator/mongo/data_store'
require 'curator/shared_data_store_specs'

module Curator
  module Mongo
    describe Curator::Mongo::DataStore do
      include_examples "data_store"

      let(:data_store) { DataStore.new }

      with_config do
        Curator.configure(:mongo) do |config|
          config.environment = "test"
          config.database = "curator"
          config.mongo_config_file = File.expand_path(File.dirname(__FILE__) + "/../../../config/mongo.yml")
        end
      end

      describe "self.client" do
        context "with a client manually configured" do
          with_config do
            Curator.configure(:mongo) do |config|
              config.environment = "test"
              config.client      = ::Mongo::Connection.new
              config.database    = "curator"
            end
          end

          it "should return the client and not use the yaml file" do
            data_store.client.should == Curator.config.client
          end
        end

        it "returns a mongo client with a config read from the yml file provided" do
          begin
            File.stub(:read).and_return(<<-YML)
            test:
              :host: localhost
              :port: 27017
            YML
            data_store.instance_variable_set('@client', nil)
            client = data_store.client
            client.host.should == 'localhost'
            client.port.should == 27017
          ensure
            data_store.instance_variable_set("@client", nil)
          end
        end
        context "returns a mongo client with" do
          after (:each) do
            data_store.instance_variable_set(:@client, nil)
            File.stub(:read).and_return(<<-YML)
            test:
              :host: localhost
              :port: 27017
            YML
            client = data_store.client
          end

          it "a specific database when included in the YML file" do
            begin
              File.stub(:read).and_return(<<-YML)
              test:
                :host: localhost
                :port: 27017
                :database: test_db_auth
              YML
              data_store.instance_variable_set(:@client, nil)
              client = data_store.client
              data_store._db_name.should == 'test_db_auth'
            ensure
              data_store.instance_variable_set(:@client, nil)
            end
          end

          it "auth configured when included in the YML file" do
            begin
              File.stub(:read).and_return(<<-YML)
              test:
                :host: localhost
                :port: 27017
                :database: test_db_auth
                :password: password1
                :username: my_username
              YML
              data_store.instance_variable_set(:@client, nil)
              client = data_store.client
              client.auths.should_not be_empty
              client.auths[0]["db_name"].should == 'test_db_auth'
              client.auths[0]["username"].should == 'my_username'
              client.auths[0]["password"].should == 'password1'
            ensure
              client.remove_auth('test_db_auth')
              data_store.instance_variable_set(:@client, nil)
            end
          end

          it "auth configured to use default database when database unspecified" do
            begin
              File.stub(:read).and_return(<<-YML)
              test:
                :host: localhost
                :port: 27017
                :password: password1
                :username: my_username
              YML
              data_store.instance_variable_set('@client', nil)
              client = data_store.client
              data_store._db_name.should == 'curator:test'
              client.auths.should_not be_empty
              client.auths[0]["db_name"].should == 'curator:test'
              client.auths[0]["username"].should == 'my_username'
              client.auths[0]["password"].should == 'password1'
            ensure
              client.remove_auth('curator:test')
              data_store.instance_variable_set('@client', nil)
            end
          end

          it "auth configured via environment variables" do
            begin
              ENV['MONGO_USERNAME'] = 'my_username'
              ENV['MONGO_PASSWORD'] = 'password1'
              File.stub(:read).and_return(<<-YML)
              test:
                :host: localhost
                :port: 27017
              YML
              data_store.instance_variable_set('@client', nil)
              client = data_store.client
              client.auths.should_not be_empty
              client.auths[0]["username"].should == 'my_username'
              client.auths[0]["password"].should == 'password1'
            ensure
              ENV['MONGO_USERNAME'] = nil
              ENV['MONGO_PASSWORD'] = nil
              client.remove_auth('curator:test')
              data_store.instance_variable_set('@client', nil)
            end
          end
        end
      end

      describe "find_by_key" do
        it "can find by a generated key as a string" do
          key = data_store.save(:collection_name => "fake_things", :value => {"k" => "v"})
          data_store.find_by_key("fake_things", key.to_s).should == {:key => key, :data => {"k" => "v"}}
        end
      end

      describe "self.save" do
        it "stores document with _id attribute in mongo" do
          data_store.save(:collection_name => 'fake_things', :key => 1, :value => {:foo => "bar"})
          data_store.client.db(data_store._db_name).collection('fake_things').find_one({'_id' => 1}).should == {"_id" => 1, "foo" => "bar"}
        end

        it "generates the key as an ObjectId if no key is specified" do
          key = data_store.save(:collection_name => 'fake_things', :value => {:foo => "bar"})
          key.should be_a(BSON::ObjectId)
        end
      end

      describe "self._db_name" do
        it "namespaces database with environment" do
          data_store.client
          data_store._db_name.should == 'curator:test'
        end
      end
    end
  end
end
