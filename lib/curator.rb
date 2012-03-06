require 'rubygems'

require 'curator/migration'
require 'curator/migrator'
require 'curator/model'
require 'curator/repository'
require 'curator/configuration'
require 'curator/riak/configuration'
require 'curator/riak/data_store'
require 'curator/resettable_riak/configuration'
require 'curator/resettable_riak/data_store'
require 'curator/memory/configuration'
require 'curator/memory/data_store'
require 'curator/mongo/configuration'
require 'curator/mongo/data_store'
require 'curator/railtie' if defined?(Rails)

module Curator
  class << self
    attr_reader :config
  end

  def self.configure(data_store, &block)
    path = "curator/#{data_store.to_s}/configuration"
    @config = path.camelize.constantize.new
    yield(@config) if block_given?
  end

  def self.data_store
    config.data_store
  end

  self.configure(:riak) do |config|
    config.environment = 'development'
    config.migrations_path = File.expand_path(File.dirname(__FILE__) + "/../db/migrate")
    config.bucket_prefix = 'curator'
    config.riak_config_file = File.expand_path(File.dirname(__FILE__) + "/../config/riak.yml")
  end
end
