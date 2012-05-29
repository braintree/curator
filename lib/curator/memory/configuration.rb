module Curator::Memory
  class Configuration
    include Curator::Configuration

    def data_store
      Curator::Memory::DataStore.new
    end
  end
end
