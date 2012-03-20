module Curator
  module Sql
    class Configuration
      include Curator::Configuration

      attr_accessor :uri

      def data_store
        Curator::Sql::DataStore
      end
    end
  end
end
