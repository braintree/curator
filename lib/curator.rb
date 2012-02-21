require 'rubygems'

require 'curator/migration'
require 'curator/migrator'
require 'curator/model'
require 'curator/repository'
require 'curator/configuration'
require 'curator/riak/data_store'
require 'curator/railtie' if defined?(Rails)

module Curator
  class << self
    attr_reader :config
  end

  def self.configure(data_store, &block)
    path = "curator/#{data_store.to_s}/configuration"
    require path
    @config ||= path.camelize.constantize.new
    yield(@config) if block_given?
  end

  self.configure(:riak) do |config|
    config.environment = 'development'
    config.migrations_path = File.expand_path(File.dirname(__FILE__) + "/../db/migrate")
    config.bucket_prefix = 'curator'
    config.riak_config_file = File.expand_path(File.dirname(__FILE__) + "/../config/riak.yml")
  end
end
