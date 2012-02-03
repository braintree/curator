module Riak
  class TestDataStore < DataStore
    def self.bucket_prefix
      job = "#{ENV['JOB_NAME'].gsub(/[^[:alnum:]]/, '_')}" if ENV['JOB_NAME'].present?
      [Riak::DataStore::BUCKET_PREFIX, job, Rails.env].compact.join(':')
    end

    def self.exclude_from_reset
      @exclude_from_reset = true
      yield
      @exclude_from_reset = false
    end

    def self.save(options)
      result = super

      unless @exclude_from_reset
        @bucket_names ||= {}
        @bucket_names[options[:collection_name]] ||= []
        @bucket_names[options[:collection_name]] << result.key
      end

      result
    end

    def self.reset!
      @bucket_names ||= {}
      deletable_buckets = @bucket_names.each do |bucket_name, keys|
         bucket = _bucket(bucket_name)
         keys.each {|key| bucket.delete(key)}
      end
      @bucket_names = {}
    end
  end
end
