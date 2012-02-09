require 'riak'
require 'yaml'

module Riak
  class DataStore
    BUCKET_PREFIX = "librarian"

    def self.client
      return @client if @client
      yml_config = YAML.load(File.read(Librarian.riak_config_file))[Librarian.environment]
      @client = Riak::Client.new(yml_config)
    end

    def self.delete(bucket_name, key)
      bucket = _bucket(bucket_name)
      object = bucket.get(key)
      object.delete
    end

    def self.ping
      client.ping
    end

    def self.save(options)
      bucket = _bucket(options[:collection_name])
      object = Riak::RObject.new(bucket, options[:key])
      object.content_type = "application/json"
      object.data = options[:value]
      options.fetch(:index, {}).each do |index_name, index_value|
        object.indexes["#{index_name}_bin"] << index_value
      end
      object.store
    end

    def self.find_by_key(bucket_name, key)
      bucket = _bucket(bucket_name)
      begin
        object = bucket.get(key)
        { :key => object.key, :data => object.data } unless object.data.empty?
      rescue Riak::HTTPFailedRequest => failed_request
        raise failed_request unless failed_request.not_found?
      end
    end

    def self.find_by_index(bucket_name, index_name, query)
      return [] if query.nil?

      bucket = _bucket(bucket_name)
      begin
        keys = _find_key_by_index(bucket, index_name.to_s, query)
        keys.map { |key| find_by_key(bucket_name, key) }
      rescue Riak::HTTPFailedRequest => failed_request
        raise failed_request unless failed_request.not_found?
      end
    end

    def self._bucket(name)
      client.bucket(_bucket_name(name))
    end

    def self._bucket_name(name)
      bucket_prefix + ":" + name
    end

    def self.bucket_prefix
      "#{BUCKET_PREFIX}:#{Librarian.environment}"
    end

    def self._find_key_by_index(bucket, index_name, query)
      bucket.get_index("#{index_name}_bin", query)
    end
  end
end
