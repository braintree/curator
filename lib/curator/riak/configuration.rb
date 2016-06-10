require 'riak'

module Curator::Riak
  class Configuration
    include Curator::Configuration

    attr_accessor :bucket_prefix, :riak_config_file

    def initialize
      ::Riak.escaper = CGI
      ::Riak.disable_list_keys_warnings = true
    end

    def data_store
      Curator::Riak::DataStore.new(self)
    end
  end
end
