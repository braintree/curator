require File.expand_path(File.dirname(__FILE__) + '/../riak/data_store')
require 'active_support/core_ext/kernel/reporting'

module Curator
  module ResettableRiak
    class DataStore < Riak::DataStore
      def bucket_prefix
        job = "#{ENV['JOB_NAME'].gsub(/[^[:alnum:]]/, '_')}" if ENV['JOB_NAME'].present?
        [@config.bucket_prefix, job, @config.environment].compact.join(':')
      end

      def exclude_from_reset(&block)
        @exclude_from_reset = true
        yield
      ensure
        @exclude_from_reset = false
      end

      def remove_all_keys
        silence_warnings do
          buckets = client.buckets.select { |bucket| bucket.name.start_with?(bucket_prefix) }
          buckets.each do |bucket|
            bucket.keys do |keys|
              keys.each { |key| bucket.delete(key) }
            end
          end
        end
      end

      def reset!
        @bucket_names ||= {}
        deletable_buckets = @bucket_names.each do |bucket_name, keys|
          bucket = _bucket(bucket_name)
          keys.each {|key| bucket.delete(key)}
        end
        @bucket_names = {}
      end

      def save(options)
        key = super

        unless @exclude_from_reset
          @bucket_names ||= {}
          @bucket_names[options[:collection_name]] ||= []
          @bucket_names[options[:collection_name]] << key
        end

        key
      end
    end
  end
end
