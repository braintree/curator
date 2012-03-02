require 'mongo'
require 'yaml'
require 'ostruct'

module Curator
  module Mongo
    class DataStore
      class << self
        def client
          return @client if @client
          config = YAML.load(File.read(Curator.config.mongo_config_file))[Curator.config.environment]
          host = config.delete(:host)
          port = config.delete(:port)
          @client = ::Mongo::Connection.new(host, port, config)
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
          document.merge!({_id: key}) unless key.nil?
          options.fetch(:index, {}).each do |index_name, index_value|
            collection.ensure_index index_name
          end
          object_id = collection.save document
          Hash[key: object_id]
        end

        def delete(collection_name, id)
          collection = _collection(collection_name)
          collection.remove(_id: id)
        end

        def find_by_index(collection_name, field, query)
          return [] if query.nil?
          
          collection = _collection(collection_name)
          documents = collection.find(field.to_sym => query)
          documents.map {|doc| normalize_document(doc) }
        end

        def find_by_key(collection_name, id)
          collection = _collection(collection_name)
          document = collection.find_one({_id: id})
          normalize_document(document) unless document.nil?
        end

        def _collection(name)
          _db.collection(name)
        end

        def _collection_name(name)
          _db.collection(name).name
        end

        def _db
          client.db(_db_name)
        end

        def _db_name
          "#{Curator.config.database}:#{Curator.config.environment}"
        end

        def normalize_document(doc)
          key = doc.delete '_id'
          Hash[key: key, data: doc]
        end
      end
    end
  end
end
