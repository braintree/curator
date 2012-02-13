require 'i18n'
require 'curator'
require 'timecop'
require 'riak/cleaner'
require 'riak/test_data_store'

Curator.environment = "test"
Curator.migrations_path = "/tmp/curator_migrations"

RSpec.configure do |config|
  config.before(:suite) do
    Riak::Cleaner.remove_all_keys
  end

  config.after(:each) do
    Riak::TestDataStore.reset!
  end
end

class TestModel
  include Curator::Model
  attr_accessor :id, :some_field
end

def test_repository(&block)
  Class.new do
    include Curator::Repository

    def self.data_store
      Riak::TestDataStore
    end

    def self.name
      "TestModelRepository"
    end

    instance_eval(&block)
  end
end

def write_migration(collection_name, filename, contents)
  collection_migration_directory = File.join(Curator.migrations_path, collection_name)
  FileUtils.mkdir_p(collection_migration_directory)

  File.open(File.join(collection_migration_directory, filename), 'w') do |file|
    file.write(contents)
  end
end
