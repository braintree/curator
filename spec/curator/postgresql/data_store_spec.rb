require 'spec_helper'
require 'curator/postgresql/data_store'
require 'curator/shared_data_store_specs'

module Curator
  module Postgresql
    describe Curator::Postgresql::DataStore do
      describe "postgresql" do
        include_examples "data_store", DataStore

        around :each do |example|
          db = Curator.data_store.client
          db.transaction(:rollback => :always) do
            example.run
          end
        end

        before :all do
          @old_config = Curator.config

          Curator.configure(:postgresql) do |config|
            config.environment = "test"
            config.postgresql_config_file = File.expand_path(File.dirname(__FILE__) + "/../../../config/postgresql.yml")
          end

          db = Curator.data_store.client

          db.create_table! :test_collection do
            primary_key :id
            String :key
            String :indexed_key
            column :indexed_array_key, 'text[]'
          end

          db.create_table! :fake_things do
            primary_key :id
            String :key
            Integer :foo
            String :bar
            String :k
          end

          db.create_table! :abyss do
            primary_key :id
            String :invalid_index
          end
        end

        after :all do
          Curator.instance_variable_set('@config', @old_config)
        end
      end
    end
  end
end
