require 'spec_helper'
require 'active_support/core_ext/numeric/time'
require 'active_support/core_ext/date/calculations'

describe Curator::Repository do
  describe "indexed_fields" do
    it "adds find methods for the indexed fields" do
      repository = test_repository do
        indexed_fields :some_field
      end

      model = TestModel.new(:some_field => "Acme Inc.")

      repository.save(model)

      repository.find_by_some_field("Acme Inc.").should == [model]
    end

    it "adds find first methods for the indexed fields" do
      repository = test_repository do
        indexed_fields :some_field
      end

      model = TestModel.new(:some_field => "Acme Inc.")

      repository.save(model)

      repository.find_first_by_some_field("Acme Inc.").should == model
    end

    it "indexes created_at and updated_at by default" do
      repository = test_repository do
      end

      model = TestModel.new(:some_field => "Acme Inc.")

      repository.save(model)

      repository.find_by_created_at(15.minutes.ago.utc, 5.minutes.ago.utc).should == []
      repository.find_by_updated_at(15.minutes.ago.utc, 5.minutes.ago.utc).should == []

      repository.find_by_created_at(5.minutes.ago.utc, Time.now.utc).should == [model]
      repository.find_by_updated_at(5.minutes.ago.utc, Time.now.utc).should == [model]

      repository.find_by_created_at(1.minute.from_now.utc, 5.minutes.from_now.utc).should == []
      repository.find_by_updated_at(1.minute.from_now.utc, 5.minutes.from_now.utc).should == []
    end

    it "indexes version by default" do
      repository = test_repository do
      end

      model = TestModel.new(:some_field => "Acme Inc.")

      repository.save(model)

      repository.find_by_version(model.version).should == [model]
      repository.find_by_version(model.version + 1).should be_empty
    end
  end

  context "find_by_index" do
    it "returns empty array if not found" do
      repository = test_repository do
        indexed_fields :some_field
      end

      repository.find_by_some_field("Doesn't exist").should == []
    end
  end

  context "find_first_by_index" do
    it "returns nil if not found" do
      repository = test_repository do
        indexed_fields :some_field
      end

      repository.find_first_by_some_field("Doesn't exist").should be_nil
    end
  end

  describe "delete" do
    it "deletes an object and returns nil" do
      repository = test_repository do
      end

      model = TestModel.new
      repository.save(model)

      repository.find_by_id(model.id).should_not be_nil
      repository.delete(model).should be_nil
      repository.find_by_id(model.id).should be_nil
    end
  end

  describe "serialization" do
    it "does not persist nil values" do
      repository = test_repository do
      end
      model = TestModel.new(
        :some_field => nil
      )

      repository.save(model)

      riak_data = Curator.data_store.find_by_key("test_models", model.id)[:data]
      riak_data.has_key?("some_field").should be_false
    end

    it "persists timestamps" do
      repository = test_repository do
      end

      created_time = Time.parse("2011-1-1 12:00 CST")
      Timecop.freeze(created_time) do
        model = TestModel.new(
          :created_at => nil,
          :updated_at => nil
        )

        repository.save(model)

        found_record = repository.find_by_id(model.id)
        found_record.created_at.should == created_time
        found_record.updated_at.should == created_time
      end
    end

    it "persists the model's current version on the initial save" do
      repository = test_repository do
      end

      class VersionedModel
        include Curator::Model
        current_version 42
        attr_accessor :id
      end

      model = VersionedModel.new
      repository.save(model)

      riak_data = Curator.data_store.find_by_key("test_models", model.id)[:data]
      riak_data["version"].should == 42
    end

    it "persists created_at on multiple saves" do
      repository = test_repository do
      end

      created_time = Time.parse("2011-1-1 12:00 CST")
      Timecop.freeze(created_time) do
        model = TestModel.new(
          :created_at => nil,
          :updated_at => nil
        )

        repository.save(model)

        found_record = repository.find_by_id(model.id)
        repository.save(found_record)

        found_record = repository.find_by_id(model.id)
        found_record.created_at.should == created_time
      end
    end

    it "updated updated_at on subsequent saves, but not created_at" do
      repository = test_repository do
      end

      model = nil
      created_time = Time.parse("2011-1-1 12:00 CST")
      Timecop.freeze(created_time) do
        model = TestModel.new(
          :created_at => nil,
          :updated_at => nil
        )

        repository.save(model)
      end

      Timecop.freeze(created_time + 1.day) do
        found_record = repository.find_by_id(model.id)
        repository.save(found_record)

        found_record = repository.find_by_id(model.id)
        found_record.created_at.should == created_time
        found_record.updated_at.should_not == created_time
      end
    end

    it "persists timestamps in UTC" do
      repository = test_repository do
      end

      created_time = Time.parse("2011-1-1 12:00 CST")
      Timecop.freeze(created_time) do
        model = TestModel.new(
          :created_at => nil,
          :updated_at => nil
        )

        repository.save(model)
        found_record = repository.find_by_id(model.id)

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
        repository = test_repository do
        end

        write_migration repository.collection_name, "0001_one.rb", <<-END
          class One < Curator::Migration
            def migrate(hash)
              hash.merge("some_field" => "new value")
            end
          end
        END

        model = TestModel.new(
          :some_field => "old value"
        )
        model.version.should == 0

        repository.save(model)

        found_record = repository.find_by_id(model.id)
        found_record.some_field.should == "new value"
        found_record.version.should == 1
      end

      it "does not run migrations if version is current" do
        repository = test_repository do
        end

        write_migration repository.collection_name, "0001_one.rb", <<-END
          class One < Curator::Migration
            def migrate(hash)
              hash.merge("some_field" => "new value")
            end
          end
        END

        model = TestModel.new(
          :some_field => "old value"
        )
        model.version = 1

        repository.save(model)

        found_record = repository.find_by_id(model.id)
        found_record.some_field.should == "old value"
        found_record.version.should == 1
      end
    end
  end

  describe "save" do
    it "returns the object that was saved" do
      repository = test_repository do
      end

      model = TestModel.new

      repository.save(model).should == model
    end
  end

  describe "save_without_timestamps" do
    it "does not update updated_at" do
      repository = test_repository do
      end

      created_time = Time.parse("2012-1-1 12:00 CST")
      model = TestModel.new

      Timecop.freeze(created_time) do
        repository.save(model)
      end

      Timecop.freeze(created_time + 1.day) do
        repository.save_without_timestamps(model)

        found_model = repository.find_by_id(model.id)
        found_model.created_at.should == created_time
        found_model.updated_at.should == created_time
      end
    end

    it "returns the object that was saved" do
      repository = test_repository do
      end

      model = TestModel.new

      repository.save_without_timestamps(model).should == model
    end
  end

  describe "mapping" do
    it "runs serialize and deserialize" do
      repository = test_repository do
        map :some_field, :serialize => lambda { |i| (i + 1).to_s }, :deserialize => lambda { |str| "5#{str}".to_i }
      end

      model = TestModel.new(:some_field => 3)
      repository.save(model)

      found_model = repository.find_by_id(model.id)
      found_model.some_field.should == 54
    end

    it "does not change value when no serialize is specified" do
      repository = test_repository do
        map :some_field, :deserialize => lambda { |str| Date.parse(str) }
      end

      model = TestModel.new(:some_field => Date.today)
      repository.save(model)

      found_model = repository.find_by_id(model.id)
      found_model.some_field.should == Date.today
    end

    it "leaves value as is when no deserialize is specified" do
      repository = test_repository do
        map :some_field, :serialize => lambda { |date| date.year }
      end

      model = TestModel.new(:some_field => Date.today)
      repository.save(model)

      found_model = repository.find_by_id(model.id)
      found_model.some_field.should == Date.today.year
    end
  end
end
