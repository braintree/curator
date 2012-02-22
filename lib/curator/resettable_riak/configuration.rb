module Curator::ResettableRiak
  class Configuration < Curator::Riak::Configuration
    def data_store
      Curator::ResettableRiak::DataStore
    end
  end
end
