require 'rubygems'

require 'curator/migration'
require 'curator/migrator'
require 'curator/model'
require 'curator/repository'
require 'curator/riak/data_store'
require 'curator/railtie' if defined?(Rails)

module Curator
  class << self
    attr_accessor :bucket_prefix, :environment, :migrations_path, :riak_config_file
  end

  self.bucket_prefix = "curator"
  self.environment = "development"
  self.migrations_path = File.expand_path(File.dirname(__FILE__) + "/../db/migrate")
  self.riak_config_file = File.expand_path(File.dirname(__FILE__) + "/../config/riak.yml")
end
