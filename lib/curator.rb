require 'rubygems'

require 'curator/migration'
require 'curator/migrator'
require 'curator/model'
require 'curator/repository'
require 'curator/riak/data_store'
require 'curator/railtie' if defined?(Rails)

module Curator
  class << self
    attr_accessor :environment, :migrations_path, :riak_config_file
  end

  self.environment = "development"
  self.riak_config_file = File.expand_path(File.dirname(__FILE__) + "/../config/riak.yml")
end
