require 'rubygems'

require 'librarian/model'
require 'librarian/riak/data_store'
require 'librarian/repository'
require 'librarian/railtie' if defined?(Rails)

module Librarian
  class << self
    attr_accessor :environment
    attr_accessor :riak_config_file
  end

  self.environment = "development"
  self.riak_config_file = File.expand_path(File.dirname(__FILE__) + "/../config/riak.yml")
end
