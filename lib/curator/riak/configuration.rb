module Curator::Riak
  class Configuration
    include Curator::Configuration

    attr_accessor :bucket_prefix, :riak_config_file

    def data_store
      Curator::Riak::DataStore
    end
  end
end
