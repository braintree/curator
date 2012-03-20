require 'spec_helper'
require 'curator/sql/data_store'
require 'curator/shared_data_store_specs'

module Curator
  module Sql
    describe Curator::Sql::DataStore do
      describe "sqlite" do
        include_examples "data_store", DataStore

        around :each do |example|
          db = Sequel.connect "sqlite://test.db"
          db.transaction(:rollback => :always) do
            example.run
          end
        end

        before :all do
          File.delete "test.db"
          db = Sequel.connect "sqlite://test.db"
          db.create_table :test_collection do
            primary_key :id
            String :key
            String :indexed_key
          end
          db.create_table :fake_things do
            primary_key :id
            String :key
            Integer :foo
            String :bar
            String :k
          end
          db.create_table :abyss do
            primary_key :id
            String :invalid_index
          end
        end

        with_config do
          Curator.configure(:sql) do |config|
            config.environment = "test"
            config.uri = "sqlite://test.db"
          end
        end
      end
    end
  end
end
