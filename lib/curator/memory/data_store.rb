require 'ostruct'

module Curator
  module Memory
    class DataStore
      def initialize(config = Curator.config)
        @config = config
      end

      def settings(bucket_name)
        {}
      end

      def update_settings!(collection_name, updated_settings)
        # NOOP
      end

      def remove_all_keys
        @data = {}
      end

      def reset!
        remove_all_keys
      end

      def save(options)
        bucket = _bucket_name(options[:collection_name])
        object = options[:value]
        key = options[:key]
        indexes = options.fetch(:index, {})

        key = _generate_key(bucket) unless key

        _records(bucket).store(key, object)
        indexes.each do |index_name, index_data|
          index = _index(bucket, index_name)

          _normalized_index_values(index_data).each do |index_value|
            index[index_value] ||= []
            index[index_value] << key unless index[index_value].include?(key)
          end
        end

        key
      end

      def delete(collection_name, key)
        bucket = _bucket_name(collection_name)
        _records(bucket).delete(key)
        _indices(bucket).each_key do |name|
          index = _index(bucket, name)
          index.each do |value, keys|
            next unless keys.include?(key)
            index[value].delete(key)
          end
          index.delete_if { |value, keys| keys.empty? }
        end
      end

      def find_all(collection_name)
        bucket = _bucket_name(collection_name)
        _records(bucket).inject([]) do |results, (key,value)|
          results << {:key => key, :data => value}
          results
        end
      end

      def find_by_key(collection_name, key)
        bucket = _bucket_name(collection_name)
        value = _records(bucket).fetch(key, nil)
        return if value.nil?
        {:key => key, :data => value}
      end

      def find_by_attribute(collection_name, attribute, query)
        return [] if query.nil?
        bucket = _bucket_name(collection_name)
        index = _index(bucket, attribute)
        keys = case query
               when Range
                 keys = index.keys.select do |key|
                   key.between?(query.first, query.last)
                 end
                 index.values_at(*keys).flatten
               else
                 index.fetch(query, [])
               end
        keys.map do |key|
          find_by_key(collection_name, key)
        end
      end

      def _data
        @data ||= {}
      end

      def _bucket(bucket)
        _data[bucket] ||= {}
      end

      def _records(bucket)
        _bucket(bucket)[:records] ||= {}
      end

      def _indices(bucket)
        _bucket(bucket)[:indices] ||= {}
      end

      def _index(bucket, index_name)
        _indices(bucket)[index_name] ||= {}
      end

      def _normalized_index_values(indexed_data)
        if indexed_data.is_a?(Array)
          indexed_data
        else
          [indexed_data]
        end
      end

      def _generate_key(bucket)
        keys = _records(bucket).keys
        keys = [0] if keys.empty?
        keys.max.next
      end

      def _bucket_name(name)
        "#{@config.environment}:#{name}"
      end
    end
  end
end
