require 'rubygems'

require 'librarian/migration'
require 'librarian/migrator'
require 'librarian/model'
require 'librarian/repository'
require 'librarian/riak/data_store'
require 'librarian/railtie' if defined?(Rails)

module Librarian
  class << self
    attr_accessor :environment, :migrations_path, :riak_config_file
  end

  self.environment = "development"
  self.riak_config_file = File.expand_path(File.dirname(__FILE__) + "/../config/riak.yml")
end
