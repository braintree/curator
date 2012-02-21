require 'i18n'
require 'curator'
require 'timecop'
require 'curator/riak/test/cleaner'
require 'curator/riak/test/resettable_data_store'

Curator.configure(:riak) do |config|
  config.environment = "test"
  config.migrations_path = "/tmp/curator_migrations"
end

RSpec.configure do |config|
  config.before(:suite) do
    Curator::Riak::Test::Cleaner.remove_all_keys
  end

  config.after(:each) do
    Curator::Riak::Test::ResettableDataStore.reset!
  end
end

class TestModel
  include Curator::Model
  attr_accessor :id, :some_field
end

def test_repository(&block)
  Class.new do
    include Curator::Repository

    self.data_store = Curator::Riak::Test::ResettableDataStore

    def self.name
      "TestModelRepository"
    end

    instance_eval(&block)
  end
end

def write_migration(collection_name, filename, contents)
  collection_migration_directory = File.join(Curator.config.migrations_path, collection_name)
  FileUtils.mkdir_p(collection_migration_directory)

  File.open(File.join(collection_migration_directory, filename), 'w') do |file|
    file.write(contents)
  end
end
