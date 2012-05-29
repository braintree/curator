module Curator::ResettableRiak
  class Configuration < Curator::Riak::Configuration
    def data_store
      Curator::ResettableRiak::DataStore.new
    end
  end
end
