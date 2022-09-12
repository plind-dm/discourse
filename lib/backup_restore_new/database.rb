# frozen_string_literal: true

module BackupRestoreNew
  DatabaseConfiguration = Struct.new(:host, :port, :username, :password, :database)

  module Database
    MAIN_SCHEMA = "public"

    def self.database_configuration
      config = ActiveRecord::Base.connection_pool.db_config.configuration_hash
      config = config.with_indifferent_access

      # credentials for PostgreSQL in CI environment
      if Rails.env.test?
        username = ENV["PGUSER"]
        password = ENV["PGPASSWORD"]
      end

      DatabaseConfiguration.new(
        config["backup_host"] || config["host"],
        config["backup_port"] || config["port"],
        config["username"] || username || ENV["USER"] || "postgres",
        config["password"] || password,
        config["database"]
      )
    end

    def self.core_migration_files
      files = Dir[Rails.root.join(Migration::SafeMigrate.post_migration_path, "**/*.rb")]

      ActiveRecord::Migrator.migrations_paths.each do |path|
        files.concat(Dir[Rails.root.join(path, "*.rb")])
      end

      files
    end

    def self.current_core_migration_version
      return 0 if !ActiveRecord::SchemaMigration.table_exists?

      core_versions = core_migration_files.map do |path|
        filename = File.basename(path)
        filename[/^\d+/]&.to_i || 0
      end

      db_versions = ActiveRecord::SchemaMigration.all_versions.map(&:to_i)
      core_versions.intersection(db_versions).max || 0
    end
  end
end
