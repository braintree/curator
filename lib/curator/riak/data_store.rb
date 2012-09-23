require 'riak'
require 'yaml'

module Curator
  module Riak
    class DataStore
      def client
        return @client if @client
        yml_config = YAML.load(File.read(Curator.config.riak_config_file))[Curator.config.environment]
        @client = ::Riak::Client.new(yml_config)
      end

      def bucket_prefix
        "#{Curator.config.bucket_prefix}:#{Curator.config.environment}"
      end

      def delete(bucket_name, key)
        bucket = _bucket(bucket_name)
        object = bucket.get(key)
        object.delete
      end

      def ping
        client.ping
      end

      def save(options)
        bucket = _bucket(options[:collection_name])
        object = ::Riak::RObject.new(bucket, options[:key])
        object.content_type = options.fetch(:content_type, "application/json")
        object.data = options[:value]
        options.fetch(:index, {}).each do |index_name, index_data|
          object.indexes["#{index_name}_bin"] << _normalized_index_data(index_data)
        end
        result = object.store
        result.key
      end

      def find_all(bucket_name)
        bucket = _bucket(bucket_name)
        bucket.keys.map { |key| find_by_key(bucket_name, key) }
      end

      def find_by_key(bucket_name, key)
        bucket = _bucket(bucket_name)
        begin
          object = bucket.get(key)
          { :key => object.key, :data => _deserialize(object.data) } unless object.data.empty?
        rescue ::Riak::HTTPFailedRequest => failed_request
          raise failed_request unless failed_request.not_found?
        end
      end

      def find_by_attribute(bucket_name, index_name, query)
        return [] if query.nil?

        bucket = _bucket(bucket_name)
        begin
          keys = _find_key_by_index(bucket, index_name.to_s, query)
          keys.map { |key| find_by_key(bucket_name, key) }
        rescue ::Riak::HTTPFailedRequest => failed_request
          raise failed_request unless failed_request.not_found?
        end
      end

      def _bucket(name)
        client.bucket(_bucket_name(name))
      end

      def _bucket_name(name)
        bucket_prefix + ":" + name
      end

      def _deserialize(data)
        deserialized_data = data.dup
        deserialized_data["created_at"] = Time.parse(data["created_at"]) if data["created_at"]
        deserialized_data["updated_at"] = Time.parse(data["updated_at"]) if data["updated_at"]
        deserialized_data
      end

      def _find_key_by_index(bucket, index_name, query)
        bucket.get_index("#{index_name}_bin", query)
      end

      def _normalized_index_data(index_data)
        if index_data.is_a?(Array)
          index_data.join(", ")
        else
          index_data
        end
      end
    end
  end
end
