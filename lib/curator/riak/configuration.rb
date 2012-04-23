require 'riak'

module Curator::Riak
  class Configuration
    include Curator::Configuration

    attr_accessor :bucket_prefix, :riak_config_file

    def initialize
      ::Riak.escaper = CGI
    end

    def data_store
      Curator::Riak::DataStore
    end
  end
end
