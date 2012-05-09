require 'spec_helper'
require 'active_support/core_ext/numeric/time'
require 'active_support/core_ext/date/calculations'
require 'curator/mongo/data_store'
require 'curator/shared_data_store_specs'

module Curator
  module Mongo
    describe Curator::Mongo::DataStore do
      include_examples "data_store", DataStore

      with_config do
        Curator.configure(:mongo) do |config|
          config.environment = "test"
          config.database = "curator"
          config.mongo_config_file = File.expand_path(File.dirname(__FILE__) + "/../../../config/mongo.yml")
        end
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
        context "returns a mongo client with" do
          after (:each) do
            DataStore.instance_variable_set(:@client, nil)
            File.stub(:read).and_return(<<-YML)
            test:
              :host: localhost
              :port: 27017
            YML
            client = DataStore.client
          end

          it "a specific database when included in the YML file" do
            begin
              File.stub(:read).and_return(<<-YML)
              test:
                :host: localhost
                :port: 27017
                :database: test_db_auth
              YML
              DataStore.instance_variable_set(:@client, nil)
              client = DataStore.client
              DataStore._db_name.should == 'test_db_auth'
            ensure
              DataStore.instance_variable_set(:@client, nil)
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
              DataStore.instance_variable_set(:@client, nil)
              client = DataStore.client
              client.auths.should_not be_empty
              client.auths[0]["db_name"].should == 'test_db_auth'
              client.auths[0]["username"].should == 'my_username'
              client.auths[0]["password"].should == 'password1'
            ensure
              client.remove_auth('test_db_auth')
              DataStore.instance_variable_set(:@client, nil)
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
              DataStore.instance_variable_set('@client', nil)
              client = DataStore.client
              DataStore._db_name.should == 'curator:test'
              client.auths.should_not be_empty
              client.auths[0]["db_name"].should == 'curator:test'
              client.auths[0]["username"].should == 'my_username'
              client.auths[0]["password"].should == 'password1'
            ensure
              client.remove_auth('curator:test')
              DataStore.instance_variable_set('@client', nil)
            end
          end
        end
      end

      describe "self.save" do
        it "stores document with _id attribute in mongo" do
          DataStore.save(:collection_name => 'fake_things', :key => 1, :value => {:foo => "bar"})
          DataStore.client.db(DataStore._db_name).collection('fake_things').find_one({'_id' => 1}).should == {"_id" => 1, "foo" => "bar"}
        end
      end

      describe "self._db_name" do
        it "namespaces database with environment" do
          DataStore::_db_name.should == 'curator:test'
        end
      end
    end
  end
end
