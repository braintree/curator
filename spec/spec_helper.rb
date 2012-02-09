require 'i18n'
require 'librarian'
require 'timecop'
require 'riak/cleaner'
require 'riak/test_data_store'

Librarian.environment = "test"

RSpec.configure do |config|
  config.before(:suite) do
    Riak::Cleaner.remove_all_keys
  end

  config.after(:each) do
    Riak::TestDataStore.reset!
  end
end

class TestModel
  include Librarian::Model
  attr_accessor :id, :some_field

  def initialize(hash = {})
    self.id = hash[:id]
    self.some_field = hash[:some_field]
  end
end

def test_repository(&block)
  Class.new do
    include Librarian::Repository

    def self.data_store
      Riak::TestDataStore
    end

    def self.name
      "TestModelRepository"
    end

    instance_eval(&block)
  end
end
