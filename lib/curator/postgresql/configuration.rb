module Curator
  module Postgresql
    class Configuration
      include Curator::Configuration

      attr_accessor :uri, :postgresql_config_file

      def data_store
        Curator::Postgresql::DataStore
      end
    end
  end
end
