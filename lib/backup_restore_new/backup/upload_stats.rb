# frozen_string_literal: true

module BackupRestoreNew
  module Backup
    class UploadStats
      attr_reader :total_count, :failed_ids
      attr_accessor :included_count

      def initialize(total_count, included_count = 0, failed_ids = [])
        @total_count = total_count
        @included_count = included_count
        @failed_ids = failed_ids
      end
    end
  end
end
