module Curator::Mongo
  class Configuration
    include Curator::Configuration

    attr_accessor :database, :mongo_config_file

    def data_store
      Curator::Mongo::DataStore.new(self)
    end
  end
end
