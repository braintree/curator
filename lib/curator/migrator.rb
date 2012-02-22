module Curator
  class Migrator
    def initialize(collection_name)
      @collection_name = collection_name
    end

    def migrate(attributes)
      migrations = _applicable_migrations(attributes["version"].to_i)
      migrations.inject(attributes) do |migrated_attributes, migration|
        migration.migrate(migrated_attributes).merge("version" => migration.version)
      end
    end

    def _applicable_migrations(current_version)
      @applicable_migrations ||= _all_migrations.select { |migration| migration.version > current_version }.sort_by(&:version)
    end

    def _all_migrations
      files = Dir.glob("#{File.join(Curator.config.migrations_path, @collection_name)}/*.rb")

      files.map do |file|
        load file
        migration_version, name = file.scan(/([0-9]+)_([_a-z0-9]*).rb/).first
        klass = name.camelize.constantize
        klass.new(migration_version.to_i)
      end
    end
  end
end
