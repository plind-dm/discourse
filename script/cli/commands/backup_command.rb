# frozen_string_literal: true

require 'thor'

module DiscourseCLI
  class BackupCommand < Thor

    desc "create", "Creates a backup"
    def create
      DiscourseCLI.load_rails

      with_logger("backup") do |logger|
        backuper = BackupRestoreV2::Backuper.new(Discourse::SYSTEM_USER_ID, logger)
        backuper.run
        exit(1) unless backuper.success
      end
    end

    desc "restore FILENAME", "Restores a backup"
    def restore(filename)

    end

    desc "list", "Lists existing backups"
    def list

    end

    desc "delete", "Deletes a backup"
    def delete

    end

    desc "download", "Downloads a backup"
    def download

    end

    no_commands do
      private def with_logger(name)
        logger = BackupRestoreV2::Logger::CliLogger.new(name)
        yield logger
      ensure
        logger.close if logger
      end
    end
  end
end
