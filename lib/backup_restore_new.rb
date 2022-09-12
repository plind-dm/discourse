# frozen_string_literal: true

module BackupRestoreNew
  DUMP_FILE = "dump.sql.gz"
  UPLOADS_FILE = "uploads.tar.gz"
  OPTIMIZED_IMAGES_FILE = "optimized-images.tar.gz"
  METADATA_FILE = "meta.json"
  LOGS_CHANNEL = "/admin/backups/logs"

  def self.current_version
    ActiveRecord::Migrator.current_version
  end
end
