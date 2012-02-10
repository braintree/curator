require "spec_helper"

describe Librarian::Migrator do
  describe "migrate" do
    after(:each) do
      FileUtils.rm_rf Librarian.migrations_path
    end

    it "migrates a given object through one migration" do
      write_migration "test_models", "0001_one.rb", <<-END
        class One < Librarian::Migration
          def migrate(hash)
            hash.merge("one" => "one")
          end
        end
      END

      migrated_hash = Librarian::Migrator.new("test_models").migrate({"version" => 0})
      migrated_hash.should == {"one" => "one", "version" => 1}
    end

    it "assumes a missing version attribute is version 0" do
      write_migration "test_models", "0001_one.rb", <<-END
        class One < Librarian::Migration
          def migrate(hash)
            hash.merge("one" => "one")
          end
        end
      END

      migrated_hash = Librarian::Migrator.new("test_models").migrate({})
      migrated_hash.should == {"one" => "one", "version" => 1}
    end

    it "runs all applicable migrations" do
      write_migration "test_models", "0001_one.rb", <<-END
        class One < Librarian::Migration
          def migrate(hash)
            hash.merge("one" => "one")
          end
        end
      END

      write_migration "test_models", "0002_two.rb", <<-END
        class Two < Librarian::Migration
          def migrate(hash)
            hash.merge("two" => "two")
          end
        end
      END

      migrated_hash = Librarian::Migrator.new("test_models").migrate({"version" => 0})
      migrated_hash.should == {"one" => "one", "two" => "two", "version" => 2}
    end

    it "only runs migrations that have a version higher than the current version" do
      write_migration "test_models", "0001_one.rb", <<-END
        class One < Librarian::Migration
          def migrate(hash)
            hash.merge("one" => "one")
          end
        end
      END

      write_migration "test_models", "0002_two.rb", <<-END
        class Two < Librarian::Migration
          def migrate(hash)
            hash.merge("two" => "two")
          end
        end
      END

      migrated_hash = Librarian::Migrator.new("test_models").migrate({"version" => 1})
      migrated_hash.should == {"two" => "two", "version" => 2}
    end

    it "only runs migrations for specified collection" do
      write_migration "other_collection", "0001_one.rb", <<-END
        class One < Librarian::Migration
          def migrate(hash)
            hash.merge("one" => "one")
          end
        end
      END

      migrated_hash = Librarian::Migrator.new("test_models").migrate({"version" => 2})
      migrated_hash.should == {"version" => 2}
    end

    context "caching" do
      it "only loads the migrations once" do
        write_migration "test_models", "0001_one.rb", <<-END
          class One < Librarian::Migration
            def migrate(hash)
              hash.merge("one" => "one")
            end
          end
        END

        migrator = Librarian::Migrator.new("test_models")
        migrator.migrate({"version" => 0}).should == {"one" => "one", "version" => 1}

        write_migration "test_models", "0001_one.rb", <<-END
          class One < Librarian::Migration
            def migrate(hash)
              hash.merge("one" => "bad value")
            end
          end
        END

        migrator.migrate({"version" => 0}).should == {"one" => "one", "version" => 1}
      end
    end
  end
end
