module Curator::Mongo
  class Configuration
    include Curator::Configuration

    attr_accessor :database, :mongo_config_file

    def data_store
      Curator::Mongo::DataStore
    end
  end
end
