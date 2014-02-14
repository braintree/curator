require 'spec_helper'
require 'active_support/core_ext/numeric/time'
require 'active_support/core_ext/date/calculations'

describe Curator::Repository do
  it "tracks all repositories" do
    def_transient_class(:TestModelRepository) do
      include Curator::Repository
      attr_reader :id
    end

    Curator.repositories.should include(TestModelRepository)
  end

  context "with riak" do
    with_config do
      Curator.configure(:resettable_riak) do |config|
        config.environment = "test"
        config.migrations_path = "/tmp/curator_migrations"
        config.bucket_prefix = 'curator'
        config.riak_config_file = File.expand_path(File.dirname(__FILE__) + "/../../config/riak.yml")
      end
    end

    describe "collection_name" do
      it "has a default value derived from the repository class name" do
        def_transient_class(:SomeModel) do
          include Curator::Model
          attr_reader :id
        end

        def_transient_class(:SomeModelRepository) do
          include Curator::Repository
        end

        SomeModelRepository.collection_name.should == "some_models"

        model = SomeModel.new()
        SomeModelRepository.save(model)

        SomeModelRepository.find_by_id(model.id).should == model
      end

      it "allows overriding the collection name" do
        def_transient_class(:SomeModel) do
          include Curator::Model
          attr_reader :id
        end

        def_transient_class(:SomeModelRepository) do
          include Curator::Repository
          collection "an_explicit_collection"
        end

        SomeModelRepository.collection_name.should == "an_explicit_collection"

        model = SomeModel.new()
        SomeModelRepository.save(model)

        SomeModelRepository.find_by_id(model.id).should == model
      end
    end

    describe "all" do
      it "finds all" do
        def_transient_class(:TestModelRepository) do
          include Curator::Repository
          attr_reader :id, :some_field
          indexed_fields :some_field
        end

        def_transient_class(:TestModel) do
          include Curator::Model
          attr_reader :id, :some_field
        end

        TestModelRepository.save(TestModel.new(:some_field => "Some Value 1"))
        TestModelRepository.save(TestModel.new(:some_field => "Some Value 2"))

        TestModelRepository.all.map(&:some_field).sort.should == ["Some Value 1", "Some Value 2"]
      end
    end

    describe "indexed_fields" do
      it "adds find methods for the indexed fields" do
        def_transient_class(:TestModelRepository) do
          include Curator::Repository
          attr_reader :id, :some_field
          indexed_fields :some_field
        end

        def_transient_class(:TestModel) do
          include Curator::Model
          attr_reader :id, :some_field
        end

        model = TestModel.new(:some_field => "Acme Inc.")
        TestModelRepository.save(model)

        TestModelRepository.find_by_some_field("Acme Inc.").should == [model]
      end

      it "adds find first methods for the indexed fields" do
        def_transient_class(:TestModelRepository) do
          include Curator::Repository
          attr_reader :id, :some_field
          indexed_fields :some_field
        end

        def_transient_class(:TestModel) do
          include Curator::Model
          attr_reader :id, :some_field
        end

        model = TestModel.new(:some_field => "Acme Inc.")
        TestModelRepository.save(model)

        TestModelRepository.find_first_by_some_field("Acme Inc.").should == model
      end

      it "can index arrays of values" do
        def_transient_class(:TestModelRepository) do
          include Curator::Repository
          attr_reader :id, :multiple_values
          indexed_fields :multiple_values
        end

        def_transient_class(:TestModel) do
          include Curator::Model
          attr_reader :id, :multiple_values
        end

        model = TestModel.new(:multiple_values => ["first", "second"])
        TestModelRepository.save(model)

        TestModelRepository.find_by_multiple_values("first").should == [model]
        TestModelRepository.find_by_multiple_values("second").should == [model]
        TestModelRepository.find_by_multiple_values("third").should == []
      end

      it "can index a ruby Set serialized as an array" do
        def_transient_class(:TestModelRepository) do
          include Curator::Repository
          attr_reader :id, :multiple_values
          indexed_fields :multiple_values

          def self.serialize(model)
            super.tap do |attributes|
              attributes[:multiple_values] = model.multiple_values.to_a
            end
          end

        end

        def_transient_class(:TestModel) do
          include Curator::Model
          attr_reader :id, :multiple_values

          def initialize(args={})
            args.each {|k,v| instance_variable_set "@#{k}", v}
            @multiple_values = Set.new(args[:multiple_values])
          end
        end

        model = TestModel.new(:multiple_values => ["first", "second"])
        TestModelRepository.save(model)

        TestModelRepository.find_by_multiple_values("first").should == [model]
        TestModelRepository.find_by_multiple_values("second").should == [model]
        TestModelRepository.find_by_multiple_values("third").should == []
      end

      it "indexes created_at and updated_at by default" do
        def_transient_class(:TestModelRepository) do
          include Curator::Repository
          attr_reader :id, :some_field
          indexed_fields :some_field
        end

        def_transient_class(:TestModel) do
          include Curator::Model
          attr_reader :id, :some_field
        end

        model = TestModel.new(:some_field => "Acme Inc.")
        TestModelRepository.save(model)

        TestModelRepository.find_by_created_at(15.minutes.ago.utc, 5.minutes.ago.utc).should == []
        TestModelRepository.find_by_updated_at(15.minutes.ago.utc, 5.minutes.ago.utc).should == []

        TestModelRepository.find_by_created_at(5.minutes.ago.utc, Time.now.utc).should == [model]
        TestModelRepository.find_by_updated_at(5.minutes.ago.utc, Time.now.utc).should == [model]

        TestModelRepository.find_by_created_at(1.minute.from_now.utc, 5.minutes.from_now.utc).should == []
        TestModelRepository.find_by_updated_at(1.minute.from_now.utc, 5.minutes.from_now.utc).should == []
      end

      it "indexes version by default" do
        def_transient_class(:TestModelRepository) do
          include Curator::Repository
          attr_reader :id, :some_field
          indexed_fields :some_field
        end

        def_transient_class(:TestModel) do
          include Curator::Model
          attr_reader :id, :some_field
        end

        model = TestModel.new(:some_field => "Acme Inc.")
        TestModelRepository.save(model)

        TestModelRepository.find_by_version(model.version).should == [model]
        TestModelRepository.find_by_version(model.version + 1).should be_empty
      end
    end

    context "find_by_index" do
      it "returns empty array if not found" do
        def_transient_class(:TestModelRepository) do
          include Curator::Repository
          attr_reader :id, :some_field
          indexed_fields :some_field
        end

        def_transient_class(:TestModel) do
          include Curator::Model
          attr_reader :id, :some_field
        end

        TestModelRepository.find_by_some_field("Doesn't exist").should == []
      end
    end

    context "find_first_by_index" do
      it "returns nil if not found" do
        def_transient_class(:TestModelRepository) do
          include Curator::Repository
          attr_reader :id, :some_field
          indexed_fields :some_field
        end

        def_transient_class(:TestModel) do
          include Curator::Model
          attr_reader :id, :some_field
        end

        TestModelRepository.find_first_by_some_field("Doesn't exist").should be_nil
      end
    end

    describe "delete" do
      it "deletes an object and returns nil" do
        def_transient_class(:TestModelRepository) do
          include Curator::Repository
          attr_reader :id, :some_field
          indexed_fields :some_field
        end

        def_transient_class(:TestModel) do
          include Curator::Model
          attr_reader :id, :some_field
        end

        model = TestModel.new
        TestModelRepository.save(model)

        TestModelRepository.find_by_id(model.id).should_not be_nil
        TestModelRepository.delete(model).should be_nil
        TestModelRepository.find_by_id(model.id).should be_nil
      end
    end

    describe "serialization" do
      it "does not persist nil values" do
        def_transient_class(:TestModelRepository) do
          include Curator::Repository
          attr_reader :id, :some_field
          indexed_fields :some_field
        end

        def_transient_class(:TestModel) do
          include Curator::Model
          attr_reader :id, :some_field
        end

        model = TestModel.new(:some_field => nil)

        TestModelRepository.save(model)

        riak_data = Curator.data_store.find_by_key("test_models", model.id)[:data]
        riak_data.has_key?("some_field").should be_false
      end

      it "persists timestamps" do
        def_transient_class(:TestModelRepository) do
          include Curator::Repository
          attr_reader :id
        end

        def_transient_class(:TestModel) do
          include Curator::Model
          attr_reader :id
        end

        created_time = Time.parse("2011-1-1 12:00 CST")
        Timecop.freeze(created_time) do
          model = TestModel.new(:created_at => nil, :updated_at => nil)

          TestModelRepository.save(model)

          found_record = TestModelRepository.find_by_id(model.id)
          found_record.created_at.should == created_time
          found_record.updated_at.should == created_time
        end
      end

      it "persists the model's current version on the initial save" do
        def_transient_class(:TestModelRepository) do
          include Curator::Repository
          attr_reader :id
        end

        def_transient_class(:TestModel) do
          include Curator::Model
          current_version 42
          attr_accessor :id
        end

        model = TestModel.new
        TestModelRepository.save(model)

        riak_data = Curator.data_store.find_by_key("test_models", model.id)[:data]
        riak_data["version"].should == 42
      end

      it "persists created_at on multiple saves" do
        def_transient_class(:TestModelRepository) do
          include Curator::Repository
          attr_reader :id
        end

        def_transient_class(:TestModel) do
          include Curator::Model
          attr_accessor :id
        end

        Timecop.freeze(created_time = Time.parse("2011-1-1 12:00 CST")) do
          model = TestModel.new(:created_at => nil, :updated_at => nil)

          TestModelRepository.save(model)

          found_record = TestModelRepository.find_by_id(model.id)
          TestModelRepository.save(found_record)

          found_record = TestModelRepository.find_by_id(model.id)
          found_record.created_at.should == created_time
        end
      end

      it "updated updated_at on subsequent saves, but not created_at" do
        def_transient_class(:TestModelRepository) do
          include Curator::Repository
          attr_reader :id
        end

        def_transient_class(:TestModel) do
          include Curator::Model
          attr_accessor :id
        end

        model = nil
        Timecop.freeze(created_time = Time.parse("2011-1-1 12:00 CST")) do
          model = TestModel.new(:created_at => nil, :updated_at => nil)
          TestModelRepository.save(model)
        end

        Timecop.freeze(created_time + 1.day) do
          found_record = TestModelRepository.find_by_id(model.id)
          TestModelRepository.save(found_record)

          found_record = TestModelRepository.find_by_id(model.id)
          found_record.created_at.should == created_time
          found_record.updated_at.should_not == created_time
        end
      end

      it "persists timestamps in UTC" do
        def_transient_class(:TestModelRepository) do
          include Curator::Repository
          attr_reader :id
        end

        def_transient_class(:TestModel) do
          include Curator::Model
          attr_accessor :id
        end

        Timecop.freeze(created_time = Time.parse("2011-1-1 12:00 CST")) do
          model = TestModel.new(:created_at => nil, :updated_at => nil)

          TestModelRepository.save(model)
          found_record = TestModelRepository.find_by_id(model.id)

          found_record.created_at.zone.should == "UTC"
          found_record.updated_at.zone.should == "UTC"
        end
      end
    end

    describe "deserialization" do
      context "migrations" do
        after(:each) do
          FileUtils.rm_rf Curator.config.migrations_path
        end

        it "runs applicable migrations" do
          def_transient_class(:TestModelRepository) do
            include Curator::Repository
            attr_reader :id, :some_field
          end

          def_transient_class(:TestModel) do
            include Curator::Model
            attr_accessor :id, :some_field
          end

          write_migration TestModelRepository.collection_name, "0001_one.rb", <<-END
          class One < Curator::Migration
            def migrate(hash)
              hash.merge("some_field" => "new value")
            end
          end
          END

          model = TestModel.new(:some_field => "old value")
          model.version.should == 0

          TestModelRepository.save(model)

          found_record = TestModelRepository.find_by_id(model.id)
          found_record.some_field.should == "new value"
          found_record.version.should == 1
        end

        it "does not run migrations if version is current" do
          def_transient_class(:TestModelRepository) do
            include Curator::Repository
            attr_reader :id, :some_field
          end

          def_transient_class(:TestModel) do
            include Curator::Model
            attr_accessor :id, :some_field
          end

          write_migration TestModelRepository.collection_name, "0001_one.rb", <<-END
              class One < Curator::Migration
                def migrate(hash)
                  hash.merge("some_field" => "new value")
                end
              end
          END

          model = TestModel.new(:some_field => "old value")
          model.version = 1

          TestModelRepository.save(model)

          found_record = TestModelRepository.find_by_id(model.id)
          found_record.some_field.should == "old value"
          found_record.version.should == 1
        end
      end
    end

    describe "save" do
      it "returns the object that was saved" do
        def_transient_class(:TestModelRepository) do
          include Curator::Repository
          attr_reader :id
        end

        def_transient_class(:TestModel) do
          include Curator::Model
          attr_accessor :id
        end

        model = TestModel.new
        TestModelRepository.save(model).should == model
      end
    end

    describe "save_without_timestamps" do
      it "does not update updated_at" do
        def_transient_class(:TestModelRepository) do
          include Curator::Repository
          attr_reader :id
        end

        def_transient_class(:TestModel) do
          include Curator::Model
          attr_accessor :id
        end

        created_time = Time.parse("2012-1-1 12:00 CST")
        model = TestModel.new

        Timecop.freeze(created_time) do
          TestModelRepository.save(model)
        end

        Timecop.freeze(created_time + 1.day) do
          TestModelRepository.save_without_timestamps(model)

          found_model = TestModelRepository.find_by_id(model.id)
          found_model.created_at.should == created_time
          found_model.updated_at.should == created_time
        end
      end

      it "returns the object that was saved" do
        def_transient_class(:TestModelRepository) do
          include Curator::Repository
          attr_reader :id
        end

        def_transient_class(:TestModel) do
          include Curator::Model
          attr_accessor :id
        end

        model = TestModel.new
        TestModelRepository.save_without_timestamps(model).should == model
      end
    end
  end

  context "with mongodb" do
    with_config do
      Curator.configure(:mongo) do |config|
        config.environment = "test"
        config.database = "curator"
        config.migrations_path = "/tmp/curator_migrations"
        config.mongo_config_file = File.expand_path(File.dirname(__FILE__) + "/../../config/mongo.yml")
      end
    end

    it "saves and retrieves created_at/updated_at as Time objects" do
      def_transient_class(:TestModelRepository) do
        include Curator::Repository
        attr_reader :id
      end

      def_transient_class(:TestModel) do
        include Curator::Model
        attr_accessor :id
      end

      model = TestModel.new
      TestModelRepository.save(model)

      model.created_at.should be_a(Time)
      model.updated_at.should be_a(Time)

      found_model = TestModelRepository.find_by_id(model.id)
      found_model.created_at.should be_a(Time)
      found_model.updated_at.should be_a(Time)
    end
  end
end
