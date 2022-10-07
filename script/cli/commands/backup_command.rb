# frozen_string_literal: true

require 'thor'

module DiscourseCLI
  class BackupCommand < Thor

    desc "create", "Creates a backup"
    def create
      DiscourseCLI.load_rails

      with_logger("backup") do |logger|
        backuper = BackupRestoreNew::Backuper.new(Discourse::SYSTEM_USER_ID, logger)
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
        require_relative '../support/logger'
        logger = DiscourseCLI::Logger.new(name)
        yield logger
      ensure
        logger.close if logger
      end
    end
  end
end
