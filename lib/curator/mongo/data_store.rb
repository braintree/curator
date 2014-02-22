require 'mongo'
require 'yaml'

module Curator
  module Mongo
    class DataStore
      def client
        return @client if @client

        if Curator.config.client
          @client        = Curator.config.client
          @database_name = Curator.config.database
          return @client
        end

        if ENV['MONGO_URI']
          require 'uri'
          uri = URI.parse(ENV['MONGO_URI'])
          @database_name = uri.path.gsub(/^\//, '')
          @client = ::Mongo::Connection.from_uri(uri.to_s)
          return @client
        end

        config = YAML.load(File.read(Curator.config.mongo_config_file))[Curator.config.environment]
        config = config.symbolize_keys

        host = config.delete(:host)
        port = config.delete(:port)
        password = ENV['MONGO_PASSWORD'] || config.delete(:password)
        username = ENV['MONGO_USERNAME'] || config.delete(:username)
        @database_name = config.delete(:database) || default_db_name
        @client = ::Mongo::Connection.new(host, port, config)
        @client.add_auth(@database_name, username, password) if username and password
        @client
      end

      def settings(collection_name)
        raise StandardError, "Not implemented yet"
      end

      def update_settings!(collection_name, updated_settings)
        raise StandardError, "Not implemented yet"
      end

      def remove_all_keys
        self.reset!
      end

      def reset!
        _db.collections.each {|coll| coll.drop unless coll.name =~ /system/ }
      end

      def save(options)
        collection = _collection options[:collection_name]
        key = options.delete(:key)
        document = options[:value]
        document.merge!({:_id => key}) unless key.nil?
        options.fetch(:index, {}).each do |index_name, index_value|
          collection.ensure_index index_name
        end
        collection.save document
      end

      def delete(collection_name, id)
        collection = _collection(collection_name)
        collection.remove(:_id => id)
      end

      def find_all(collection_name)
        collection = _collection(collection_name)
        documents = collection.find
        documents.map {|doc| normalize_document(doc) }
      end

      def find_by_attribute(collection_name, field, query)
        return [] if query.nil?

        exp = {}
        exp[field] = query
        collection = _collection(collection_name)
        documents = collection.find(_normalize_query(exp))
        documents.map {|doc| normalize_document(doc) }
      end

      def find_by_key(collection_name, id)
        collection = _collection(collection_name)
        document = _find_by_key_as_provided(collection, id) || _find_by_key_as_object_id(collection, id)
        normalize_document(document) unless document.nil?
      end

      def _find_by_key_as_provided(collection, id)
        collection.find_one(:_id => id)
      end

      def _find_by_key_as_object_id(collection, id)
        if BSON::ObjectId.legal?(id)
          collection.find_one(:_id => BSON::ObjectId.from_string(id))
        end
      end

      def _collection(name)
        _db.collection(name)
      end

      def _db
        client.db(_db_name)
      end

      def default_db_name
        "#{Curator.config.database}:#{Curator.config.environment}"
      end

      def _db_name
        @database_name
      end

      def normalize_document(doc)
        key = doc.delete '_id'
        Hash[:key => key, :data => doc]
      end

      def _normalize_query(query)
        query.inject({}) do |hash, (key, value)|
          case value
          when Range
            hash[key] = {'$gte' => value.first, '$lt' => value.last}
          else
            hash[key] = value
          end
          hash
        end
      end
    end
  end
end
