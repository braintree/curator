require File.expand_path(File.dirname(__FILE__) + '/../riak/configuration')

module Curator::ResettableRiak
  class Configuration < Curator::Riak::Configuration
    def data_store
      Curator::ResettableRiak::DataStore.new(self)
    end
  end
end
